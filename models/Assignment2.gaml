/**
* Name: Assignment2
* Based on the internal empty template. 
* Author: Teddy
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
	point current_auction <-nil;
	
	init{
		possible_interest <- categories at rnd(0,length(categories)-1);
	}
	
	aspect base {
		draw circle(2) color: mycolor;
	}
	
	reflex moving {
		do wander;
	}
	
	reflex reply_broadcast when:(time = 2) { //At time two means that this reflex is accessed just to answer the broadcast message
		message request_from_auctioneer <- cfps at 0;
		list<string> interest <- request_from_auctioneer.contents;
		write '(Time ' + time + '): ' + name + ' receives a cfp message from ' + agent(request_from_auctioneer.sender).name + ' with content ' + request_from_auctioneer.contents;
		
		if (interest contains possible_interest) {
			write '\t' + name + ' sends a propose message to ' + agent(request_from_auctioneer.sender).name;
			current_auction <- auctioneer(request_from_auctioneer.sender).location;
			do propose with: (message: request_from_auctioneer,contents:['I am interested!']);
		}else{
			write '\t' + name + ' sends a refuse message to ' + agent(request_from_auctioneer.sender).name;
			do refuse with: (message: request_from_auctioneer, contents:['I am not interested!'] ); 
		}
	}
	
	reflex go_to_auction when: current_auction != nil{
		mycolor <- #yellow;
		do goto target:current_auction - 2;
		
	}
}
species merch {
	string category <- nil;
	string name <- nil ;
	int quantity <- 0;
	int price <- 0;
	bool sold <- false;
	
	init{
		category <- categories at rnd(0,length(categories) - 1);
		quantity <- rnd(1,2);
		price <- rnd(1000,5000);
		name <- category + price ;
	}
}

species auctioneer skills:[fipa] {
	int over_estimation_rate <- 50 ; //The auctioneer adds 50% to the item actual price 
	int under_estimation_rate <- 10 ; // The auctioneer minimum value is acual_product_price - (actual_product_price*10 )/100
	rgb mycolor <- #grey;
	merch first;
	list<merch> merchandising <- nil;

	int current_merch <- 0; //Merch that I am selling right now, index of merchandising list
	
	init{
		ask merch{
			add self to: myself.merchandising;
		}
	}
	
	aspect base {
		draw rectangle(5,10) color: mycolor;
	}
	/*Dutch auction are Open cry and descending
	 * Auctioneer starts at an artificially high price. 
	 * Then continually lowers the offer price until an 
	 * agent makes a bid which is equal to the current offer price.
	 * The winner then pays his price.
	 * When multiple auctions are auctioned the first winner takes his price and later winners pay less
	 * Strategy: Get the bid a bit below true willingness to pay!
	 * If the price is reduced below the auctioneer minimum value the auction is cancelled
	 */
	 reflex send_broadcast when: (time =1) {
		write '(Time ' + time + '): ' + name + ' sends a cfp message to all participants';
		
	 	string merch_category <- (merchandising at current_merch).category;
		do start_conversation with:[to :: people, protocol::'fipa-contract-net', performative :: 'cfp', contents:: [merch_category] ];
	 }
	 
	 reflex read_propose_message when: !(empty(proposes)){
	 	write '(Time ' + time + '): ' + name + ' receives propose messages';
	 	
	 	loop p over: proposes{
	 		write 'I got it you '+ string(p.contents);
	 	}
	 }
	 
	 reflex read_refuse_message when: !(empty(refuses)){
	 	write '(Time ' + time + '): ' + name + ' receives refuse messages';
	 	
	 	loop r over: refuses{
	 		write 'I got it you are '+ (string(r.contents));
	 	}
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
