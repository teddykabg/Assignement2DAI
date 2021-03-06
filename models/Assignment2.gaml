/**
* Name: Assignment2
* Based on the internal empty template. 
* Author: Teddy & Nik
* Tags: 
*/


model Assignment2

/* Insert your model definition here */

global{
	/*Global variables and initialization */
	int number_of_people <- 20;
	int number_of_auctioneers <- 1;
	int number_of_merch <- 2;
	list<string> categories <- ["Frame","Car","Watch","Wine"];
	list<person> people <-nil;
	
	int number_of_people_B <- 5;
	int number_of_auctioneers_B <- 1;
	int number_of_merch_B <- 2;
	list<string> categories_B <- ["Frame","Car","Watch","Wine"];
	list<person_B> people_B <-nil;
	
	int number_of_people_C <- 5;
	int number_of_auctioneers_C <- 1;
	int number_of_merch_C <- 2;
	list<string> categories_C <- ["Frame","Car","Watch","Wine"];
	list<person_C> people_C <-nil;
	
	init {
		create person number: number_of_people returns: peeps;
		add peeps all: true to:people;
		
		create merch number: number_of_merch;
		create auctioneer number: number_of_auctioneers;
		
		create person_B number: number_of_people_B returns: peeps;
		add peeps all: true to:people_B;
		
		create merch_B number: number_of_merch_B;
		create auctioneer_B number: number_of_auctioneers_B;
		
		create person_C number: number_of_people_C returns: peeps;
		add peeps all: true to:people_C;
		
		create merch_C number: number_of_merch_C;
		create auctioneer_C number: number_of_auctioneers_C;
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
	
	reflex reply_to_broadcast when: !(empty(informs)) and current_auction = nil { //At time two means that this reflex is accessed just to answer the broadcast message
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
			write '(Time ' + time + '): ' + name + ' receives a (CLOSE) message from ' + agent(request_from_auctioneer.sender).name;
			
			current_auction <- nil;
			mycolor <- #green;
		}
	}
	
	reflex reply_to_offer when: !(empty(cfps)) and current_auction != nil{
		message request_from_auctioneer <- cfps at 0;
		list message_content <- request_from_auctioneer.contents;
		int proposed_price <- int(message_content at 1); //The price is the second element of the array sent by the auctioneer
		
		write '(Time ' + time + '): ' + name + ' receives cfp messages from '+agent(request_from_auctioneer.sender).name
			+' with content ' + request_from_auctioneer.contents;
		
		write 'Willing to buy for '+buying_price;
		
		if(proposed_price > buying_price ){
			write '@@@@@ '+name+' rejects for '+proposed_price;
			do refuse with: (message: request_from_auctioneer, contents:['I reject'+proposed_price] ); 
		}
		else{
			write '***** '+name+' buys for '+proposed_price;
			do propose with: (message: request_from_auctioneer, contents:['BUY',proposed_price] ); 
			mycolor <- #red;
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
	int over_estimation_rate <- 50 ; //The auctioneer adds 50% to the item actual price 
	int under_estimation_rate <- 10 ; // The auctioneer minimum value is acual_product_price - (actual_product_price*10 )/100
	rgb mycolor <- #grey;
	merch first;
	float start_time <- 1.0;
	int current_price <- 0;
	list<person> current_partecipants <- nil;
	list<merch> merchandising <- nil;
	int replies_received <- 0;
	int min_possible <- 0;
	bool open <- false; //denotes that is not the first round, so if the product hasn't been bought I can decrese the price
	bool no_items <- false;
	

	int current_merch <- 0; //Merch that I am selling right now, index of merchandising list
	
	init{
		ask merch{
			add self to: myself.merchandising;
		}
	}
	
	bool end_auction{
		open <- false;
		proposes <- [];
	 	refuses <- [];
		informs <- [];
		
		do start_conversation with:[to :: current_partecipants, protocol::'no-protocol', performative :: 'inform', contents:: ['Close'] ];
		
		current_merch <- current_merch+1;
	 	current_partecipants <- nil;
	 	min_possible <- 0;
	 	current_price <- 0;
	 	replies_received <- 0;
	 	
	 	if(current_merch < length(merchandising)){
	 		start_time <- time + 3.0; //This means that during the next 3 cycles a new auction is going to start
	 		write 'I am starting a new auction I will let you know soon';
	 	}else{
	 		write 'Auction ENDED';
	 		no_items <- true;
	 		cfps <- [];
	 	}
	 	
	 	replies_received <- replies_received+1;
	 	
		return true;
	}
	
	bool auction_setup {
		merch actual_merch <- merchandising at current_merch;
	 	float start_price <- actual_merch.price + ((actual_merch.price * over_estimation_rate)/100);
	 	min_possible <- actual_merch.price - int((actual_merch.price*under_estimation_rate)/100);
	 	write 'Current merch min price '+min_possible+'$';
	 	current_price <- int(start_price);
	 	write 'Current price is '+current_price+'$';
	 	
		return true;
	}
	
	aspect base {
		draw rectangle(5,10) color: mycolor;
	}
	
	 reflex send_broadcast when: (time = start_time) and !no_items{ //time will become a variable, time in which i have sent the broadcast is important
		write '*********************** NEW AUCTION********************************';
		write '(Time ' + time + '): ' + name + ' sends a inform message to all participants';
	 	string merch_category <- (merchandising at current_merch).category; //Telling everybody what am I selling
		do start_conversation with:[to :: people, protocol::'no-protocol', performative :: 'inform', contents:: [merch_category] ];
	 }
	 
	 reflex doing_auction when: length(current_partecipants) >=2 and (replies_received = length(current_partecipants)) and !no_items  {
	 	merch actual_merch <- merchandising at current_merch;
	 	replies_received <- 0;
	 	
	 	write '(Time ' + time + '): ' + name + ' sends a cfp message to all participants';
	 	
	 	if(open){
	 		
	 		current_price <- current_price - int((current_price*rnd(20,30))/100); // If is not the first round I decrese the current price by 20...50%
	 		if(current_price > min_possible ){
	 			write 'Selling '+actual_merch.name+' for price '+current_price+ '$';
	 			
	 			do start_conversation with:[to :: current_partecipants, protocol::'fipa-contract-net',
	 										performative :: 'cfp', contents:: [actual_merch.name,current_price] ];			
	 		}
	 		else{
	 			write 'Selling '+actual_merch.name+' for price '+current_price+ '$';
	 			write 'Item not sold price too low now';
	 			
	 			do end_auction;
	 		}	
	 	}
	 	else{
	 		write 'Selling '+actual_merch.name+' for price '+current_price+ '$';
	 		
	 		do start_conversation with:[to :: current_partecipants, protocol::'fipa-contract-net',
	 									performative :: 'cfp', contents:: [actual_merch.name,current_price] ];	
	 		open <- true;
	 	}
	 									
	 }
	 
	 reflex read_partecipants_message when: !(empty(proposes)) and !open and !no_items and time = start_time + 2.0{
		replies_received <- 0;
	 	loop p over: proposes{
	 		write 'Adding partecipants';
	 		add p.sender to:current_partecipants ;
	 		write '(Time ' + time + '): ' + name + ' receives propose messages from '+ agent(p.sender).name+' with content '+p.contents;
	 		replies_received <- replies_received +1;
	 	}
	 	
	 	//Setting initial price etc..
	 	write 'Setting up the auction!';
	 	do auction_setup;
	 }
	 
	 reflex read_propose_message when: !(empty(proposes)) and open and !no_items{
	 	message message_ <- proposes at 0;
	 	write '(Time ' + time + '): ' + name + ' receives propose messages from '+agent(message_.sender).name;
	 	if(list(message_.contents) contains 'BUY'){
	 		write 'Item sold for '+current_price+' $ to '+agent(message_.sender).name;

	 		do end_auction;
	 	}
	 	
	 }
	 
	 reflex read_refuse_message when: !(empty(refuses)) and open and !no_items{
	 		write '(Time ' + time + '): ' + name + ' receives refuse messages from '+(refuses at 0).contents;
	 		replies_received <- replies_received+1;
	 	
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

species person_C skills:[moving,fipa] {
	rgb mycolor <- #green;
	string possible_interest <- nil;
	auctioneer_C current_auction <-nil;
	int buying_price <- 0; //Price at which the buyer is willing to buy the merch_C
	bool subscribed <- false;
	
	init{
		possible_interest <- categories_C at rnd(0,length(categories_C)-1);
		buying_price <- rnd(2000,4000);
	}
	
	aspect base {
		draw circle(2) color: mycolor;
	}
	
	reflex moving when: current_auction = nil {
		do wander;
	}
	
	reflex reply_to_Croadcast when: !(empty(informs)) and current_auction = nil {
		message request_from_auctioneer <- informs at 0;
		list<string> information <- request_from_auctioneer.contents;
		write '(Time ' + time + '): ' + name + ' receives a inform message from ' + agent(request_from_auctioneer.sender).name + ' with content ' + request_from_auctioneer.contents;
		
		if ((information contains possible_interest) and !subscribed) {
			write '\t' + name + ' sends a subscription message to ' + agent(request_from_auctioneer.sender).name;
			current_auction <- auctioneer_C(request_from_auctioneer.sender);
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

species merch_C {
	string category <- nil;
	string name <- nil ;
	int quantity <- 0;
	int price <- 0;
	
	init{
		category <- categories_C at rnd(0,length(categories_C) - 1);
		quantity <- rnd(1,2);
		price <- rnd(2000,3000);
		name <- category + price ;
	}
}

species auctioneer_C skills:[fipa] {
	int minimum_price_rate <- 10 ; // The auctioneer minimum value is acual_product_price - (actual_product_price*10 )/100
	rgb mycolor <- #grey;
	merch_C first;
	float start_time <- 1.0;
	list<person_C> current_partecipants <- nil;
	list<merch_C> merchandising <- nil;
	int replies_received <- 0;
	float winning_price <- 0.0;
	float paying_price <- 0.0;
	int proposed_prices <- 0;
	person_C current_winner <- nil;
	bool open <- false; //denotes that is not the first round, so if the product hasn't been bought I can decrese the price
	

	int current_merch <- 0; //Merch that I am selling right now, index of merchandising list
	
	init{
		ask merch_C{
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
		merch_C actual_merch <- merchandising at current_merch;
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
		do start_conversation with:[to :: people_C, protocol::'no-protocol', performative :: 'inform', contents:: [merch_category] ];
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
		 		current_winner <- person_C(agent(message_.sender));
		 		if(winning_price > 0.0){
	 				paying_price <- winning_price;
	 			} else {
	 				paying_price <- float(list(message_.contents) at 1);
	 			}
		 		winning_price <- float(list(message_.contents) at 1);
	 		} else if(float(list(message_.contents) at 1) > paying_price) {
	 				paying_price <- float(list(message_.contents) at 1);
	 		}
	 		proposed_prices <- proposed_prices + 1;
	 	}
	 	
	 	if(proposed_prices >= length(current_partecipants)){
	 		write current_winner.name + ' wins with price of ' + paying_price + '$';
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
	
	parameter "Number of Auctioneers: " var: number_of_auctioneers_B;
	parameter "Number of people_B" var:number_of_people_B;
	parameter "Number of merch_Bandising" var:number_of_merch_B;
	
	parameter "Number of Auctioneers: " var: number_of_auctioneers_C;
	parameter "Number of people_C" var:number_of_people_C;
	parameter "Number of merch_Candising" var:number_of_merch_C;
	
	output {
		display my_display {
			species auctioneer aspect:base ;
			species person aspect:base ;
			
			species auctioneer_B aspect:base ;
			species person_B aspect:base ;
			
			species auctioneer_C aspect:base ;
			species person_C aspect:base ;
		}
	}
}
