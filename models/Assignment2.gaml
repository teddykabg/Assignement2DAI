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
	
	init {
		create person number: number_of_people ;
		create merch number: number_of_merch;
		create auctioneer number: number_of_auctioneers;
		
	}
}

species person skills:[moving,fipa] {
	rgb mycolor <- #green;
	string possible_interest <- nil;
	
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
		message request_from_auctioneer <- requests at 0;
		list<string> interest <- request_from_auctioneer.contents;
		
		if (interest contains possible_interest) {
			do agree with: (message: request_from_auctioneer,contents:['I am interested!']);
		}else{
			//do failure (message: request_from_auctioneer, contents:['I am not interested!'] ); //Gives error with this line 
		}

		
		
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
	list<person> people <- nil;
	int current_merch <- 0; //Merch that I am selling right now, index of merchandising list
	
	init{
		ask merch{
			add self to: myself.merchandising;
		}
		ask person{
			add self to: myself.people;
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
		write "Sending broadcast to all people around";
	 	string merch_category <- (merchandising at current_merch).category;
	 	
	 	loop p over: people{ 
	 		do start_conversation(to :: [p], protocol::'fipa-request', performative :: 'request', contents:: [merch_category] );
	 	}
	 }
	 
	 reflex read_agree_message when: !(empty(agrees)){
	 	loop a over: agrees{
	 		
	 		write 'I got it you '+ string(a.contents);
	 	}
	 }
	 
	 reflex read_failure_message when: !(empty(failures)){
	 	loop f over: failures{
	 		write 'I got it you are '+ (string(f.contents));
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
