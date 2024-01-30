/**
* Name: ex3
* Based on the internal empty template. 
* Author: Xuan Tung
* Tags: 
*/


model ex3

/* Insert your model definition here */
global{
	int cell_width <-50;
	int cell_height <-50;
	int neighborhood_size <-8;
	
	int nb_butterfly_init <-240;
	int butterfly_nb_max_offsprings <- 10;
	float butterfly_proba_reproduce <- 0.01;
	int butterfly_life_cycle <-200;
	int nb_butterfly_dead <-0;
	int nb_butterfly_born <-0;
	string algorithm <- "Dijkstra" among: ["A*", "Dijkstra"] parameter: true;
	int nb_predator_init <- 10;
	int color_threshold_camouflage <-30;
	float color_increment <- 255/cell_width;
	float step <- 1#h;
	string color_changed_type_string;
	int nb_times_camouflage;
	int nb_butterfly -> {length(butterfly)};
	int nb_predator -> {length(predator)};
	int nb_butterfly_white ->{length(butterfly where(each.red_color=255))};
	int nb_butterfly_black->{length(butterfly where(each.red_color=0))};
	int nb_butterfly_gray->{length(butterfly where(each.red_color=127))};
	int color_changed_type <-6;
	float seed_value <- 42.0;
	float predator_prob_hunt_dominant <- 0.9;
	init{
		create butterfly number: nb_butterfly_init;
		create predator number: nb_predator_init;
	}
	reflex pause_simulation when:(nb_butterfly+nb_predator=cell_width*cell_height) or(nb_butterfly=0) or (cycle>200){
		do pause;
	}
}

species butterfly{
	cell my_cell;
	rgb color;
	int my_cycle <-0;
	image_file my_icon;
	int red_color;
	init{
		float prob <- rnd(0.0, 1.0);
		if (nb_butterfly_black<=nb_butterfly_init/3){
			red_color <-0;
			my_icon <-image_file("../includes/blackbutterfly.png");
		}else if (nb_butterfly_white<nb_butterfly_init/3){
			red_color <-255;
			my_icon <-image_file("../includes/whitebutterfly.png");
		} else{
			red_color <- 127;
			my_icon <-image_file("../includes/graybutterfly.png");
		}

		color <-rgb(red_color, red_color, red_color, 255);
		my_cell <- one_of(cell where(each.is_occupied=false));	
		my_cell.is_occupied <- true;
		location <- my_cell.location;
	}
	
	reflex move when: (current_date.hour > 9 and current_date.hour < 17){
		list<cell>next_cell_no_predator <- my_cell.neighbors where(empty(predator inside each));
		list<cell>next_cell_no_butterfly <- next_cell_no_predator where(empty(butterfly inside each));
		list<cell>next_cell_no_occupied <-next_cell_no_butterfly where(each.is_occupied=false);
		if (length(next_cell_no_occupied)>0){
			
			cell next_cell <- one_of(shuffle(next_cell_no_occupied));
			my_cell.is_occupied <- false;
			my_cell <- next_cell;
			location <- next_cell.location ;
			my_cell.is_occupied <- true;

		}

	}
	
	
	reflex count_cycle{
		my_cycle <- my_cycle+1;
	}
	reflex butterfly_die when: ((my_cycle+1) mod butterfly_life_cycle=0){
		nb_butterfly_dead <- nb_butterfly_dead +1;
		do die;
	}
	
	// reproduce with probability, much more smooth
	reflex reproduce when: flip(butterfly_proba_reproduce) and (current_date.hour > 9 and current_date.hour < 17){
		list<cell>cell_surroundings <- my_cell.neighbors where(!(empty(butterfly inside each)));
		if (length(cell_surroundings) > 0){
			cell choosen <- one_of(cell_surroundings);
			butterfly butterfly_choosen <- (butterfly inside choosen)[0];
			rgb butterfly_surrounding_color <- butterfly_choosen.color;
			
			// white + white = white, black + black = black
			if (butterfly_surrounding_color = color){
				loop times: rnd(1, butterfly_nb_max_offsprings){
					list<cell>next_cell_not_occupied <- my_cell.neighbors where(each.is_occupied=false);
					list<cell>next_cell_no_predator <-next_cell_not_occupied where(empty(predator inside each));
					list<cell>next_cell_no_butterfly <- next_cell_no_predator where(empty(butterfly inside each));
					if (length(next_cell_no_butterfly) > 0){
						create species(self) number: 1{
							cell next_cell <- one_of(next_cell_no_butterfly);
							self.my_cell <- next_cell;
							self.location <-next_cell.location;
//							my_cell <- offspring_cell;
//							location <- offspring_cell.location;
							self.my_cell.is_occupied <- true;
							self.red_color <- myself.red_color;
							self.color <- rgb(red_color, red_color, red_color, 255);
							self.my_icon <- myself.my_icon;

							nb_butterfly_born <- nb_butterfly_born+1;
						}
					}
				}
			}
			
			// reproduction with gray butterfly
			else{
				loop times: rnd(1, butterfly_nb_max_offsprings){
					list<cell>next_cell_not_occupied <- my_cell.neighbors where(each.is_occupied=false);
					list<cell>next_cell_no_predator <-next_cell_not_occupied where(empty(predator inside each));
					list<cell>next_cell_no_butterfly <- next_cell_no_predator where(empty(butterfly inside each));
					if (length(next_cell_no_butterfly) > 0){
						create species(self) number: 1{
//							cell offspring_cell <- one_of(offspring_neighbors);
							cell next_cell <- one_of(next_cell_no_butterfly);
							self.my_cell <- next_cell;
							self.location <-next_cell.location;
//							my_cell <- offspring_cell;
//							location <- offspring_cell.location;
							self.my_cell.is_occupied<- true;
							nb_butterfly_born <- nb_butterfly_born+1;
							// gray + gray => 25% white 25% black 50% gray
							if (myself.red_color=127) and(butterfly_choosen.red_color=127){
								float prob <- rnd(0.0, 1.0);
								if(prob < 1/4){
									self.red_color <- 255;
									self.my_icon <-image_file("../includes/whitebutterfly.png");
								}else if (prob>1/4 and prob <1/2){
									self.red_color <- 0;
									self.my_icon <-image_file("../includes/blackbutterfly.png");
								}else{
									self.red_color <- 127;
									self.my_icon <-image_file("../includes/graybutterfly.png");
								}
							}
							// gray + black/white => 50% gray 50% black/white
							else{
								if(flip(0.5)){
									self.red_color <- myself.red_color;
									self.my_icon <-myself.my_icon;
								}else{
									self.red_color <- butterfly_choosen.red_color;
									self.my_icon <-butterfly_choosen.my_icon;
								}
							}
							self.color <- rgb(self.red_color, self.red_color, self.red_color, 255);
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
	point goal;
	point source;
	path target_path;
	butterfly target_butterfly;
	float x;
	float y;
	init{
		my_cell <- one_of(cell where(each.is_occupied=false));	
		my_cell.is_occupied <- true;
		location <- my_cell.location;
	}
	
	reflex choose_target when: ((dead(target_butterfly) or (goal=nil) or(target_butterfly=nil))) and 
	(((current_date.hour > 6 and current_date.hour < 18) and (flip(0.25))) or (current_date.hour > 18 or current_date.hour < 6))
	{
		target_butterfly <-nil;
		list<cell>next_cell <- my_cell.neighbors where(empty(predator inside each));
		list<cell>dup_next_cell <- my_cell.neighbors where(empty(predator inside each));
		
		//instead of chasing the butterflies at distance 1, now the predator chases the butterflies at distance 2 (24 cells around it)
		loop v over: next_cell{
			loop k over: v.neighbors{
				int a;
				loop t over: dup_next_cell{
					if (k=t or k=my_cell){
						a <-a+1;
					}
				}
				if (a=0){
					dup_next_cell <<k;
				}
			}
		}
		
		list<cell>target <- dup_next_cell where(!(empty(butterfly inside each)));
		if flip(predator_prob_hunt_dominant){
			if (length(target)>0){
				cell target_cell <- first(shuffle(target));
				target_butterfly <- (butterfly inside target_cell)[0];
				source <- my_cell.location;
				goal <-target_butterfly.my_cell.location;
			}
		} else{
			list<butterfly>butterflies;
			loop t over:target{
				butterflies <<(butterfly inside t)[0];	
			} 
				
			int dominant_color;
			int white <- butterflies count(each.red_color=255);
			int black <- butterflies count(each.red_color=0);
			int gray <- butterflies count(each.red_color=127);
			dominant_color <- get_most_color(white, black, gray);
			butterflies <- butterflies where (each.red_color=dominant_color);
			if (length(butterflies)>0){
				target_butterfly <- first(shuffle(butterflies));
				source <- my_cell.location;
				goal <-target_butterfly.my_cell.location;
			}
		}

//		string hunting_type;
//		if flip (0.5){
//			hunting_type <- 'dominant';
//		} else{
//			hunting_type <- 'rare';
//		}

	}
	
	reflex move when: (((current_date.hour > 6 and current_date.hour < 18) and (flip(0.25))) or (current_date.hour > 18 or current_date.hour < 6)){
		if (goal !=nil and target_butterfly!=nil and !dead(target_butterfly)){
			source <- my_cell.location;
			goal <- target_butterfly.my_cell.location;
			using topology(cell) {
				target_path <- path_between((cell as_map (each::each.grid_value)), source, goal);
				x <- point(target_path.vertices at 1).x;
				y <- point(target_path.vertices at 1).y;
				
			}
		}
		list<cell> next_cell_no_predator <- my_cell.neighbors where(empty(predator inside each));
		if (goal!=nil and target_butterfly!=nil and !dead(target_butterfly)){
			list<cell>next_cell_goal <- next_cell_no_predator where(each.location.x=x and each.location.y=y);
			if (length(next_cell_goal)>0){
				cell next_cell <- first(next_cell_goal);
				do set_next_cell(next_cell);
				list<butterfly>butterflies <-butterfly inside next_cell;
				
				if (length(butterflies)>0){
					if (first(butterflies)=target_butterfly){
						if (abs(my_cell.red_color-butterflies[0].red_color) > color_threshold_camouflage){
							target_butterfly<-nil;
							goal <- nil;
							x<-0.0;
							y<-0.0;
							target_path <- nil;
							source <-nil;
							nb_butterfly_dead <- nb_butterfly_dead +1;
							ask butterflies{
								do die;
							}	
						
						} else{
							nb_times_camouflage <- nb_times_camouflage + 1;
						}
					} else{
						if (abs(my_cell.red_color-butterflies[0].red_color) > color_threshold_camouflage){
							nb_butterfly_dead <- nb_butterfly_dead +1;
							ask butterflies{
								do die;
							}	
						}
						else{
							nb_times_camouflage <- nb_times_camouflage + 1;
						}
					}

		
				}
			} else{
				cell next_cell <-first(next_cell_no_predator);
				do set_next_cell(next_cell);
				list<butterfly>butterflies <-butterfly inside next_cell;
				if (length(butterflies)>0){
					if (abs(my_cell.red_color-butterflies[0].red_color) > color_threshold_camouflage){
						nb_butterfly_dead <- nb_butterfly_dead +1;
						ask butterflies{
							do die;
						}	
						
					} else{
						nb_times_camouflage <- nb_times_camouflage + 1;
					}
		
				}
			}
		}
		else if(target_butterfly=nil or goal=nil) {
			cell next_cell <- one_of(next_cell_no_predator);
			do set_next_cell(next_cell);
			list<butterfly>butterflies <-butterfly inside next_cell;
			if (length(butterflies)>0){
				if (abs(my_cell.red_color-butterflies[0].red_color) > color_threshold_camouflage){
					nb_butterfly_dead <- nb_butterfly_dead +1;
					ask butterflies{
						do die;
					}	
					
				}else{
					nb_times_camouflage <- nb_times_camouflage + 1;
				}
	
			}
		}	

	}
	
	action set_next_cell(cell next_cell){
		my_cell.is_occupied<- false;
		my_cell <- next_cell;
		location <- next_cell.location ;
		my_cell.is_occupied<- true;
	}
	
	action get_most_color(int nb_white, int nb_black, int nb_gray){
		int max_butterflies_surroundings <- max(nb_white, nb_black, nb_gray);
		int red_color;
		if (max_butterflies_surroundings=nb_white and max_butterflies_surroundings=nb_black){
			if (flip (0.5)){
				red_color <-255;
			}else{
				red_color <-0;
			}
			
		} else if(max_butterflies_surroundings=nb_white and max_butterflies_surroundings=nb_gray){
			if (flip (0.5)){
				red_color <-255;
			}else{
				red_color <-127;
			}
		} else if(max_butterflies_surroundings=nb_black and max_butterflies_surroundings=nb_gray){
			if (flip (0.5)){
				red_color <-0;
			}else{
				red_color <-127;
			}
		}else if(max_butterflies_surroundings=nb_black and max_butterflies_surroundings=nb_gray and max_butterflies_surroundings=nb_white){
			float prob <-rnd(0.0, 1.0);
			if (prob <1/3){
				red_color <-0;
			}else if (prob>1/3 and prob <2/3){
				red_color <-127;
			}else{
				red_color <- 255;
			}
		} else{
			if (max_butterflies_surroundings = nb_white){
			    red_color <- 255;
			}
			else if (max_butterflies_surroundings = nb_black){
			    red_color <- 0;
			}
			else{
			    red_color <- 127;
			}
			
		}
		return red_color;
	}
	
	

	aspect base{
		draw my_icon color: #blue size:1.7;
	}
}


grid cell height:cell_height width:cell_width neighbors: neighborhood_size optimizer: algorithm{
	rgb color;
	int red_color;
	bool is_occupied <-false;
	list<cell> neighbors  <- (self neighbors_at neighborhood_size);
	
	init{
		// init gradient environment (this code can adapt to any cell_width, cell_height)
		int color_value <- int(grid_x*color_increment);
		red_color <- color_value;
		color <-rgb(red_color, red_color, red_color, 255);
	}
	reflex change_color{
		float prob <-rnd(0.0, 1.0);
		int color_value;
		if (current_date.hour >0 and current_date.hour<6 or(current_date.hour >21)){
			color_value <- 0;
		} else if(current_date.hour > 6 and current_date.hour<15){
			color_value <- 255;
		}else{
			if (color_changed_type=1){
				color_changed_type_string <- 'horizontal l->r';
				color_value <- int((grid_x-cycle mod cell_width+cell_width)mod cell_width*color_increment);
				
			}
			else if (color_changed_type=2){
				color_changed_type_string <- 'vertical t->b';
				color_value <- int((grid_y-cycle mod cell_height + cell_height)mod cell_height*color_increment);
				
			}else if (color_changed_type=3){
				color_changed_type_string <- 'horizontal r->l';
				color_value <- int((grid_x+cycle mod cell_width)mod cell_width*color_increment);
			}else if (color_changed_type=4){
				color_changed_type_string <- 'vertical b->t';
				color_value <- int((grid_y+cycle mod cell_width)mod cell_height*color_increment);
				
			}else if (color_changed_type=5){
				color_changed_type_string <- 'random color';
				color_value <- rnd(0, 255);
				
			}
			else{
				color_changed_type_string <- 'mixture';
				if (prob < 0.2){
					//color increase horizontally (left to right)
					color_value <- int((grid_x+cycle mod cell_width)mod cell_width*color_increment);
				}else if(prob > 0.2 and prob < 0.4){
					//color increase vertically (up to down)
					color_value <- int((grid_y+cycle mod cell_width)mod cell_height*color_increment);
				}else if (prob > 0.4 and prob < 0.6){
					//color increase horizontally (right to left)
					color_value <- int((grid_x-cycle mod cell_width+cell_width)mod cell_width*color_increment);
				}
				else if (prob > 0.6 and prob < 0.8){
					//color increase vertically (down to up)
					color_value <- int((grid_y-cycle mod cell_height + cell_height)mod cell_height*color_increment);
				} else{
					color_value <- rnd(0, 255);
				}		
			}
			
		}
		
		red_color <- color_value;
		color <-rgb(red_color, red_color, red_color, 255);
	}
}

experiment exp_3 type: gui until: (nb_butterfly=0) or (cycle > 200) {
	float seed <- seed_value;
	output {
		display main_display {
			grid cell border: #black;
			species butterfly aspect: base;
			species predator aspect: base;
			
			
		}
		display Population_information refresh: every(5#cycles)  type: 2d {
			chart "Butterfly evolution" type: series size: {1,0.5} position: {0, 0} {
				data "White butterfly population" value: nb_butterfly_white color: #blue;
				data "Black butterfly population" value: nb_butterfly_black color: #green;
				data "Gray butterfly population" value: nb_butterfly_gray color: #red;
			}
		}

		monitor "Number of butterfly" value: nb_butterfly;
		monitor "Number of times camouflage" value: nb_times_camouflage;
		monitor "Number of dead butterfly" value: nb_butterfly_dead;
		monitor "Number of born butterfly" value: nb_butterfly_born;
		monitor "Number of white butterfly" value: nb_butterfly_white;
		monitor "Number of black butterfly" value: nb_butterfly_black;
		monitor "Number of gray butterfly" value: nb_butterfly_gray;
		monitor "Number of predators" value: nb_predator;
	}
}


experiment exp_3_optimization_population type: batch repeat: 16 keep_seed:true until: (nb_butterfly=8) or (cycle > 200) {
	float seed <- seed_value;
	parameter "color_changed_type" var: color_changed_type min: 1 max: 6 step: 1;
	parameter " predator_prob_hunt_dominant" var: predator_prob_hunt_dominant min: 0.7 max: 0.9 step: 0.1;
	method tabu 
        iter_max: 5 tabu_list_size: 5 
        minimize: abs(int(nb_butterfly/3-nb_butterfly_black))+abs(int(nb_butterfly/3-nb_butterfly_gray))+abs(int(nb_butterfly/3-nb_butterfly_white));
	
}

experiment exp_best_result type: batch repeat: 16 keep_seed:true until: (nb_butterfly=8) or (cycle > 200) {
	float seed <- seed_value;
	parameter "color_changed_type" var: color_changed_type min: 6 max: 6 step: 1;
	parameter " predator_prob_hunt_dominant" var: predator_prob_hunt_dominant min: 0.9 max: 0.9 step: 0.1;
	permanent {
		display batch_display type:2d{
			chart "Butterfly population chart" type: series 
				x_serie_labels: (color_changed_type_string + " "+ predator_prob_hunt_dominant) x_label: 'Type of color transition'{						
				data "Mean_butterfly_white_population" value: mean(simulations collect each.nb_butterfly_white) color: #blue;
				data "Mean_butterfly_black_population" value: mean(simulations collect each.nb_butterfly_black) color: #green;
				data "Mean_butterfly_gray_population" value: mean(simulations collect each.nb_butterfly_gray) color: #red;
							
			}
		}		
	}
	reflex{
		save [cycle, simulations mean_of each.nb_butterfly_white, simulations mean_of each.nb_butterfly_black,
			simulations mean_of each.nb_butterfly_gray
		] to: "ex3_batch.csv" format: "csv";
	}
	
}