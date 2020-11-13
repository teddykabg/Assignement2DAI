/**
* Name: Assignment2
* Based on the internal empty template. 
* Author: Nicola
* Tags: 
*/


model Assignment2_sealed

/* Insert your model definition here */

global{
	/*Global variables and initialization */
	int number_of_people <- 5;
	int number_of_auctioneers <- 1;
	int number_of_merch <- 2;
	list<string> categories <- ["Frame","Car","Watch","Wine"];
	list<person> people <-nil;
	
	init {
		create person number: number_of_people returns: peeps;
		add peeps all: true to:people;
		
		create merch number: number_of_merch;
		create auctioneer number: number_of_auctioneers;
		
	}
}

species person skills:[moving,fipa] {
	rgb mycolor <- #green;
	string possible_interest <- nil;
	auctioneer current_auction <-nil;
	int buying_price <- 0; //Price at which the buyer is willing to buy the merch
	bool subscribed <- false;
	
	init{
		possible_interest <- categories at rnd(0,length(categories)-1);
		buying_price <- rnd(2000,4000);
	}
	
	aspect base {
		draw circle(2) color: mycolor;
	}
	
	reflex moving when: current_auction = nil {
		do wander;
	}
	
	reflex reply_to_broadcast when: !(empty(informs)) and current_auction = nil {
		message request_from_auctioneer <- informs at 0;
		list<string> information <- request_from_auctioneer.contents;
		write '(Time ' + time + '): ' + name + ' receives a inform message from ' + agent(request_from_auctioneer.sender).name + ' with content ' + request_from_auctioneer.contents;
		
		if ((information contains possible_interest) and !subscribed) {
			write '\t' + name + ' sends a subscription message to ' + agent(request_from_auctioneer.sender).name;
			current_auction <- auctioneer(request_from_auctioneer.sender);
			do propose with: (message: request_from_auctioneer,contents:['I am interested!']);
			subscribed <- true;
			
		}else if(!subscribed){
			write '\t' + name + ' sends a not interested in the auction message to ' + agent(request_from_auctioneer.sender).name;
			do refuse with: (message: request_from_auctioneer, contents:['I am not interested!'] ); 
		}
	}
	
	reflex receive_close_info when: !(empty(informs)) and current_auction != nil {
		message request_from_auctioneer <- informs at 0;
		list<string> information <- request_from_auctioneer.contents;
		
		if(information contains 'Close'){
			write '(Time ' + time + '): ' + name + ' receives a  (CLOSE) message from ' + agent(request_from_auctioneer.sender).name;
			
			current_auction <- nil;
			mycolor <- #green;
		}
	}
	
	reflex reply_to_offer when: !(empty(cfps)) and current_auction != nil{
		message request_from_auctioneer <- cfps at 0;
		list message_content <- request_from_auctioneer.contents;
		int minimum_price <- int(message_content at 1);
		
		write '(Time ' + time + '): ' + name + ' receives cfp messages from '+agent(request_from_auctioneer.sender).name
			+' with content ' + request_from_auctioneer.contents;
		
		if(minimum_price > buying_price ){
			write name+' rejects because minumim price is too high';
			do refuse with: (message: request_from_auctioneer, contents:['Reject'+minimum_price] ); 
		}
		else{
			write '***** '+name+' proposes for '+buying_price;
			do propose with: (message: request_from_auctioneer, contents:['BUY',buying_price] ); 
		}
		
	}
	
	reflex go_to_auction when: current_auction != nil{
		mycolor <- #yellow;
		do goto target:(current_auction.location) - 2;
		
	}
	
}

species merch {
	string category <- nil;
	string name <- nil ;
	int quantity <- 0;
	int price <- 0;
	
	init{
		category <- categories at rnd(0,length(categories) - 1);
		quantity <- rnd(1,2);
		price <- rnd(2000,3000);
		name <- category + price ;
	}
}

species auctioneer skills:[fipa] {
	int minimum_price_rate <- 10 ; // The auctioneer minimum value is acual_product_price - (actual_product_price*10 )/100
	rgb mycolor <- #grey;
	merch first;
	float start_time <- 1.0;
	list<person> current_partecipants <- nil;
	list<merch> merchandising <- nil;
	int replies_received <- 0;
	float winning_price <- 0.0;
	int proposed_prices <- 0;
	person current_winner <- nil;
	bool open <- false; //denotes that is not the first round, so if the product hasn't been bought I can decrese the price
	

	int current_merch <- 0; //Merch that I am selling right now, index of merchandising list
	
	init{
		ask merch{
			add self to: myself.merchandising;
		}
	}
	
	bool end_auction{
		open <- false;
		
		do start_conversation with:[to :: current_partecipants, protocol::'no-protocol', performative :: 'inform', contents:: ['Close'] ];
		
		current_merch <- current_merch+1;
	 	current_partecipants <- nil;
	 	replies_received <- 0;
	 	
	 	if(current_merch < length(merchandising)){
	 		start_time <- time + 3.0; //This means that during the next 3 cycles a new auction is going to start
	 		write 'I am starting a new auction I will let you know soon';
	 	}else{
	 		write 'Auction ENDED';
	 		cfps <- [];
	 		proposes <- [];
	 		refuses <- [];
	 	}
	 	
	 	replies_received <- replies_received + 1;
	 	
		return true;
	}
	
	bool auction_setup {
		merch actual_merch <- merchandising at current_merch;
	 	float minimum_price <- float(actual_merch.price - int((actual_merch.price*minimum_price_rate)/100));
	 	write 'Initial minimum price '+minimum_price+'$';
	 	
	 	do start_conversation with:[to :: current_partecipants, protocol::'fipa-contract-net',
	 										performative :: 'cfp', contents:: [actual_merch.name,minimum_price] ];	
	 	
		return true;
	}
	
	aspect base {
		draw rectangle(5,10) color: mycolor;
	}
	
	 reflex send_broadcast when: (time = start_time) { //time will become a variable, time in which i have sent the broadcast is important
		write '*********************** NEW AUCTION********************************';
		write '(Time ' + time + '): ' + name + ' sends a inform message to all participants';
	 	string merch_category <- (merchandising at current_merch).category; //Telling everybody what am I selling
		do start_conversation with:[to :: people, protocol::'no-protocol', performative :: 'inform', contents:: [merch_category] ];
	 }
	 
	 reflex read_partecipants_message when: !(empty(proposes)) and !open{
		replies_received <- 0;
	 	loop p over: proposes{
	 		write 'Adding partecipants';
	 		add p.sender to:current_partecipants ;
	 		write '(Time ' + time + '): ' + name + ' receives propose messages from '+ agent(p.sender).name+' with content '+p.contents;
	 		replies_received <- replies_received +1;
	 	}
	 	
	 	//Setting initial price etc..
	 	do auction_setup;
	 }
	 
	 reflex open_auction when: length(current_partecipants)>0 and replies_received >= length(current_partecipants) and !open{
	 	open <- true;
	 	write "Start receiving buying proposals";
	 }
	 
	 reflex read_propose_message when: !(empty(proposes)) and open{
	 	message message_ <- proposes at 0;
	 	write '(Time ' + time + '): ' + name + ' receives propose messages from '+agent(message_.sender).name;
	 	if(list(message_.contents) contains 'BUY'){
	 		if(winning_price < float(list(message_.contents) at 1)){
		 		current_winner <- person(agent(message_.sender));
		 		winning_price <- float(list(message_.contents) at 1);
	 		}
	 		proposed_prices <- proposed_prices + 1;
	 	}
	 	
	 	if(proposed_prices >= length(current_partecipants)){
	 		write current_winner.name + ' wins with price of ' + winning_price + '$';
	 		do end_auction;
	 	}
	 	
	 }
	 
	 reflex read_refuse_message when: !(empty(refuses)) and open{
	 		write '(Time ' + time + '): ' + name + ' receives refuse messages from '+(refuses at 0).contents;
	 		replies_received <- replies_received+1;
	 }
	  

	 
}

experiment Auction_simulation type: gui {
	parameter "Number of Auctioneers: " var: number_of_auctioneers;
	parameter "Number of people" var:number_of_people;
	parameter "Number of merchandising" var:number_of_merch;
	
	output {
		display my_display {
			species auctioneer aspect:base ;
			species person aspect:base ;
		}
	}
	
}
