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
	int number_of_people_B <- 5;
	int number_of_auctioneers_B <- 1;
	int number_of_merch_B <- 2;
	list<string> categories_B <- ["Frame","Car","Watch","Wine"];
	list<person_B> people_B <-nil;
	
	init {
		create person_B number: number_of_people_B returns: peeps;
		add peeps all: true to:people_B;
		
		create merch_B number: number_of_merch_B;
		create auctioneer_B number: number_of_auctioneers_B;
		
	}
}

species person_B skills:[moving,fipa] {
	rgb mycolor <- #green;
	string possible_interest <- nil;
	auctioneer_B current_auction <-nil;
	int buying_price <- 0; //Price at which the buyer is willing to buy the merch_B
	bool subscribed <- false;
	
	init{
		possible_interest <- categories_B at rnd(0,length(categories_B)-1);
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
			current_auction <- auctioneer_B(request_from_auctioneer.sender);
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

species merch_B {
	string category <- nil;
	string name <- nil ;
	int quantity <- 0;
	int price <- 0;
	
	init{
		category <- categories_B at rnd(0,length(categories_B) - 1);
		quantity <- rnd(1,2);
		price <- rnd(2000,3000);
		name <- category + price ;
	}
}

species auctioneer_B skills:[fipa] {
	int minimum_price_rate <- 10 ; // The auctioneer minimum value is acual_product_price - (actual_product_price*10 )/100
	rgb mycolor <- #grey;
	merch_B first;
	float start_time <- 1.0;
	list<person_B> current_partecipants <- nil;
	list<merch_B> merch_Bandising <- nil;
	int replies_received <- 0;
	float winning_price <- 0.0;
	int proposed_prices <- 0;
	person_B current_winner <- nil;
	bool open <- false; //denotes that is not the first round, so if the product hasn't been bought I can decrese the price
	

	int current_merch_B <- 0; //merch_B that I am selling right now, index of merch_Bandising list
	
	init{
		ask merch_B{
			add self to: myself.merch_Bandising;
		}
	}
	
	bool end_auction{
		open <- false;
		
		do start_conversation with:[to :: current_partecipants, protocol::'no-protocol', performative :: 'inform', contents:: ['Close'] ];
		
		current_merch_B <- current_merch_B+1;
	 	current_partecipants <- nil;
	 	replies_received <- 0;
	 	
	 	if(current_merch_B < length(merch_Bandising)){
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
		merch_B actual_merch_B <- merch_Bandising at current_merch_B;
	 	float minimum_price <- float(actual_merch_B.price - int((actual_merch_B.price*minimum_price_rate)/100));
	 	write 'Initial minimum price '+minimum_price+'$';
	 	
	 	do start_conversation with:[to :: current_partecipants, protocol::'fipa-contract-net',
	 										performative :: 'cfp', contents:: [actual_merch_B.name,minimum_price] ];	
	 	
		return true;
	}
	
	aspect base {
		draw rectangle(5,10) color: mycolor;
	}
	
	 reflex send_broadcast when: (time = start_time) { //time will become a variable, time in which i have sent the broadcast is important
		write '*********************** NEW AUCTION********************************';
		write '(Time ' + time + '): ' + name + ' sends a inform message to all participants';
	 	string merch_B_category <- (merch_Bandising at current_merch_B).category; //Telling everybody what am I selling
		do start_conversation with:[to :: people_B, protocol::'no-protocol', performative :: 'inform', contents:: [merch_B_category] ];
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
		 		current_winner <- person_B(agent(message_.sender));
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
	parameter "Number of Auctioneers: " var: number_of_auctioneers_B;
	parameter "Number of people_B" var:number_of_people_B;
	parameter "Number of merch_Bandising" var:number_of_merch_B;
	
	output {
		display my_display {
			species auctioneer_B aspect:base ;
			species person_B aspect:base ;
		}
	}
	
}
