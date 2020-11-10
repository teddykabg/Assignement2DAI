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
	
	init {
		create person number: number_of_people ;
		create auctioneer number: number_of_auctioneers;

	}
}

species person skills:[moving] {
	rgb mycolor <- #green;
	
	aspect base {
		draw circle(2) color: mycolor;
	}
	
	reflex moving {
		do wander;
	}
}

species auctioneer {
	rgb mycolor <- #grey;
	aspect base {
		draw rectangle(5,10) color: mycolor;
	}
}

experiment Auction_simulation type: gui {
	parameter "Number of Auctioneers: " var: number_of_auctioneers;
	parameter "Number of people" var:number_of_people;
	
	init{
		
	}
	
	output {
		display my_display {
			species auctioneer aspect:base ;
			species person aspect:base ;
		}
	}
	
}
