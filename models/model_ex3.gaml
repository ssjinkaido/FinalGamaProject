/**
* Name: basemodel
* Based on the internal empty template. 
* Author: Xuan Tung
* Tags: 
*/


model modelex3

/* Insert your model definition here */
global{
	int cell_width <-50;
	int cell_height <-50;
	int neighborhood_size <-8;
	
	int nb_butterfly_init <-150;
	int butterfly_nb_max_offsprings <- 10;
	float butterfly_proba_reproduce <- 0.01;
	int butterfly_life_cycle <-300;
	
	int nb_predator_init <-10;
	int color_threshold_camouflage <-30;
	float color_increment <- 255/(cell_width-1);
	float step <- 1#h;
	
	int nb_butterfly -> {length(butterfly)};
	int nb_predator -> {length(predator)};
	int nb_butterfly_white ->{length(butterfly where(each.red=255))};
	int nb_butterfly_black->{length(butterfly where(each.red=0))};
	int nb_butterfly_gray->{length(butterfly where(each.red=127))};

	init{
		create butterfly number: nb_butterfly_init;
		create predator number: nb_predator_init;
	}
}

species butterfly{
	cell my_cell;
	rgb color;
	int my_cycle <-0;
	image_file my_icon;
	int green;
	int blue;
	int red;
	init{
		float prob <- rnd(0.0, 1.0);
		if (prob < 1/3){
			red <-0;
			green <-0;
			blue <-0;
			color <-rgb(red, green, blue, 255);
			my_icon <-image_file("../includes/blackbutterfly.png");
		}
		else if (prob > 1/3) and (prob < 2/3){
			red <-255;
			green <-255;
			blue <-255;
			color <-rgb(red, green, blue, 255);
			my_icon <-image_file("../includes/whitebutterfly.png");
		}
		else{
			red <-127;
			green <-127;
			blue <-127;
			color <-rgb(red, green, blue, 255);
			my_icon <-image_file("../includes/graybutterfly.png");
		}
		my_cell <- one_of(cell where(each.is_occupied=false));	
		my_cell.is_occupied <-true;
		location <-my_cell.location;
	}
	
	reflex count_cycle{
		my_cycle <- my_cycle+1;
	}
	reflex butterfly_die when: ((my_cycle+1) mod butterfly_life_cycle=0){
		write "Die";
		do die;
	}

	// reproduce once in its lifecycle, in the middle of its lifecycle
	reflex reproduce when: ((my_cycle+1) mod (butterfly_life_cycle/2)=0){
		list<cell>cell_surroundings <- my_cell.neighbors where(!(empty(butterfly inside each)));
		if (length(cell_surroundings)>0){
			cell choosen <- one_of(cell_surroundings);
			butterfly butterfly_choosen <-(butterfly inside choosen)[0];
			rgb butterfly_surrounding_color <- butterfly_choosen.color;
			
			// white + white = white, black + black = black
			if (butterfly_surrounding_color=color){
				loop times: rnd(1, butterfly_nb_max_offsprings){
					list<cell>offspring_neighbors<- my_cell.neighbors where(each.is_occupied=false);
					if (length(offspring_neighbors)>0){
						create species(self) number: 1{
							cell offspring_cell <-one_of(offspring_neighbors);
							my_cell <- offspring_cell;
							location <- offspring_cell.location;
							my_cell.is_occupied<- true;
							red <- myself.red;
							blue <- myself.blue;
							green <- myself.green;
							color <- rgb(red, green, blue, 255);
						}
					}
				}
			}
			
			// reproduction with gray butterfly
			else{
				loop times: rnd(1, butterfly_nb_max_offsprings){
					list<cell>offspring_neighbors<- my_cell.neighbors where(each.is_occupied=false);
					if (length(offspring_neighbors)>0){
						create species(self) number: 1{
							cell offspring_cell <-one_of(offspring_neighbors);
							my_cell <- offspring_cell;
							location <- offspring_cell.location;
							my_cell.is_occupied<- true;
							// gray + gray => 25% white 25% black 50% gray
							if (myself.red=127) and(butterfly_choosen.red=127){
								float prob <- rnd(0.0, 1.0);
								if(prob < 1/4){
									red <- 255;
									green <- 255;
									blue <- 255;
								}else if (prob>1/4 and prob <1/2){
									red <- 0;
									green <- 0;
									blue <- 0;
								}else{
									red <- 127;
									green <- 127;
									blue <- 127;
								}
							}
							// gray + black/white => 50% gray 50% black/white
							else{
								if(flip(0.5)){
									red <- myself.red;
									green <- myself.green;
									blue <- myself.blue;
								}else{
									red <- butterfly_choosen.red;
									green <- butterfly_choosen.green;
									blue <- butterfly_choosen.blue;
								}
							}
						}
					}
				}
			}
		}
	}


	aspect base{
		draw my_icon color: color size:2.3;
	}
}


species predator {
	cell my_cell;
	image_file my_icon <- image_file("../includes/wolf.png");
	init{
		my_cell <- one_of(cell where(each.is_occupied=false));	
		my_cell.is_occupied <- true;
		location <- my_cell.location;
	}
	
	reflex move{
		cell next_cell <- one_of(my_cell.neighbors where(empty(predator inside each)));
		int color_dominant <- get_most_color();
		
		// extension 1: hunt the most dominant color 
		list<butterfly>butterflies <-butterfly inside next_cell where (each.red=color_dominant);
		if (length(butterflies)>0){
			if (abs(my_cell.red-butterflies[0].red) > color_threshold_camouflage
				and abs(my_cell.green-butterflies[0].green) > color_threshold_camouflage
				and abs(my_cell.blue-butterflies[0].blue) > color_threshold_camouflage){
				ask butterflies{
					do die;
				}	
				
			}

		}
		my_cell.is_occupied<- false;
		next_cell.is_occupied<- true;
		my_cell <- next_cell;
		location <- next_cell.location ;	
	}
	
	action get_most_color{
		int max_butterflies <- max(nb_butterfly_white, nb_butterfly_black, nb_butterfly_gray);
		int red_color;
		if (max_butterflies = nb_butterfly_white){
		    red_color <- 255;
		}
		else if (max_butterflies = nb_butterfly_black){
		    red_color <- 0;
		}
		else{
		    red_color <- 127;
		}
		return red_color;
	}
	

	aspect base{
		draw my_icon color: #blue size:1.8;
	}
}


grid cell height:cell_height width:cell_width neighbors: neighborhood_size{
	rgb color;
	int green;
	int blue;
	int red;
	bool is_occupied <-false;
	list<cell> neighbors  <- (self neighbors_at neighborhood_size);
	
	init{
		// init gradient environment
		int color_value <- int((location.x-1)/2*color_increment);
		red <- color_value;
		green <- color_value;
		blue <- color_value;	
		color <-rgb(red, green, blue, 255);
	}
	
	//extension 2: gradient change in each cycle
	reflex change_color{
		int color_value <- int((location.x-1+ cycle*2)mod 100/2*color_increment);
		red <- color_value;
		green <- color_value;
		blue <- color_value;
		color <-rgb(color_value, color_value, color_value, 255);
	}
}



experiment exp type: gui {
	output {
		display main_display {
			grid cell border: #black;
			species butterfly aspect: base;
			species predator aspect: base;
		}
		display Population_information refresh: every(5#cycles)  type: 2d {
			chart "Species evolution" type: series size: {1,0.5} position: {0, 0} {
				data "number_of_white_butterflies" value: nb_butterfly_white color: #blue;
				data "number_of_black_butterflies" value: nb_butterfly_black color: #green;
				data "number_of_gray_butterflies" value: nb_butterfly_gray color: #red;
				data "number_of_gray_butterflies" value: nb_butterfly color: #purple;
				
			}
		}
		monitor "Number of butterfly" value: nb_butterfly;
		monitor "Number of white butterfly" value: nb_butterfly_white;
		monitor "Number of black butterfly" value: nb_butterfly_black;
		monitor "Number of gray butterfly" value: nb_butterfly_gray;
		monitor "Number of predators" value: nb_predator;
	}
}



experiment exp_params type: batch repeat: 8 until: (nb_butterfly=0) or (cycle>100) {
	parameter "nb_predators_init:" var: nb_predator_init min: 30 max: 100 step: 5;
	permanent {
		display raise_level type:2d{
			chart "Butterfly chart" type: series 
				x_serie_labels: (nb_predator_init) x_label: 'number_of_butterfly'{						
				data "mean_butterfly_white" value: mean(simulations collect each.nb_butterfly_white);
				data "mean_butterfly_black" value: mean(simulations collect each.nb_butterfly_black);
				data "mean_butterfly_gray" value: mean(simulations collect each.nb_butterfly_gray);
					
							
			}
		}		
	}
	
}
