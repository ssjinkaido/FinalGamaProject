/**
* Name: basemodel
* Based on the internal empty template. 
* Author: Xuan Tung
* Tags: 
*/


model modelex1

/* Insert your model definition here */
global{
	int cell_width <-50;
	int cell_height <-50;
	int neighborhood_size <-8;
	
	int nb_butterfly_init <-250;
	int butterfly_nb_max_offsprings <- 10;
	float butterfly_proba_reproduce <- 0.005;
	int butterfly_life_cycle <-200;
	int nb_dead <-0;
	int nb_born <-0;
	string algorithm <- "Dijkstra" among: ["A*", "Dijkstra"] parameter: true;
	int nb_predator_init <-20;
	int color_threshold_camouflage <-30;
	float color_increment <- 255/cell_width;
	float step <- 1#h;
	
	int nb_times_camouflage;
	int nb_butterfly -> {length(butterfly)};
	int nb_predator -> {length(predator)};
	int nb_butterfly_white ->{length(butterfly where(each.red=255))};
	int nb_butterfly_black->{length(butterfly where(each.red=0))};
	int nb_butterfly_gray->{length(butterfly where(each.red=127))};

	init{
		create butterfly number: nb_butterfly_init;
		create predator number: nb_predator_init;
		
		
	}
	reflex pause_simulation when:(nb_butterfly+nb_predator=cell_width*cell_height) or(nb_butterfly=0){
		do pause;
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
			red <- 127;
			green <- 127;
			blue <- 127;
			color <-rgb(red, green, blue, 255);
			my_icon <-image_file("../includes/graybutterfly.png");
		}
		my_cell <- one_of(cell where(each.is_occupied=false));	
		my_cell.is_occupied <- true;
		location <- my_cell.location;
	}
	
	reflex move{
		list<cell>next_cell_no_predator <- my_cell.neighbors where(empty(predator inside each));
		list<cell>next_cell_no_butterfly <- next_cell_no_predator where(empty(butterfly inside each));
		if (length(next_cell_no_butterfly)>0){
			cell next_cell <- one_of(next_cell_no_butterfly);
			my_cell.is_occupied <- false;
			next_cell.is_occupied <- true;
			my_cell <- next_cell;
			location <- next_cell.location ;

		}

	}
	
	reflex count_cycle{
		my_cycle <- my_cycle+1;
	}
	reflex butterfly_die when: ((my_cycle+1) mod butterfly_life_cycle=0){
		nb_dead <- nb_dead +1;
		do die;
	}
	
	// reproduce with probability, much more smooth
	reflex reproduce when: flip(butterfly_proba_reproduce){
		list<cell>cell_surroundings <- my_cell.neighbors where(!(empty(butterfly inside each)));
		if (length(cell_surroundings) > 0){
			cell choosen <- one_of(cell_surroundings);
			butterfly butterfly_choosen <- (butterfly inside choosen)[0];
			rgb butterfly_surrounding_color <- butterfly_choosen.color;
			
			// white + white = white, black + black = black
			if (butterfly_surrounding_color = color){
				loop times: rnd(1, butterfly_nb_max_offsprings){
					list<cell>offspring_neighbors <- my_cell.neighbors where(each.is_occupied=false);
					if (length(offspring_neighbors) > 0){
						create species(self) number: 1{
							cell offspring_cell <- one_of(offspring_neighbors);
							my_cell <- offspring_cell;
							location <- offspring_cell.location;
							my_cell.is_occupied <- true;
							red <- myself.red;
							blue <- myself.blue;
							green <- myself.green;
							color <- rgb(red, green, blue, 255);
							my_icon <- myself.my_icon;

							nb_born <- nb_born+1;
						}
					}
				}
			}
			
			// reproduction with gray butterfly
			else{
				loop times: rnd(1, butterfly_nb_max_offsprings){
					list<cell>offspring_neighbors <- my_cell.neighbors where(each.is_occupied=false);
					if (length(offspring_neighbors) > 0){
						create species(self) number: 1{
							cell offspring_cell <- one_of(offspring_neighbors);
							my_cell <- offspring_cell;
							location <- offspring_cell.location;
							my_cell.is_occupied<- true;
							nb_born <- nb_born+1;
							// gray + gray => 25% white 25% black 50% gray
							if (myself.red=127) and(butterfly_choosen.red=127){
								float prob <- rnd(0.0, 1.0);
								if(prob < 1/4){
									self.red <- 255;
									self.green <- 255;
									self.blue <- 255;
									my_icon <-image_file("../includes/whitebutterfly.png");
								}else if (prob>1/4 and prob <1/2){
									self.red <- 0;
									self.green <- 0;
									self.blue <- 0;
									my_icon <-image_file("../includes/blackbutterfly.png");
								}else{
									self.red <- 127;
									self.green <- 127;
									self.blue <- 127;
									my_icon <-image_file("../includes/graybutterfly.png");
								}
							}
							// gray + black/white => 50% gray 50% black/white
							else{
								if(flip(0.5)){
									self.red <- myself.red;
									self.green <- myself.green;
									self.blue <- myself.blue;
									my_icon <-myself.my_icon;
								}else{
									self.red <- butterfly_choosen.red;
									self.green <- butterfly_choosen.green;
									self.blue <- butterfly_choosen.blue;
									my_icon <-butterfly_choosen.my_icon;
								}
							}
							self.color <- rgb(self.red, self.green, self.blue, 255);
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
	point goal <-nil;
	point source;
	path the_path;
	butterfly target_butterfly <-nil;
	float x;
	float y;
	init{
		my_cell <- one_of(cell where(each.is_occupied=false));	
		my_cell.is_occupied <- true;
		location <- my_cell.location;
	}
	
	reflex choose_target when: (dead(target_butterfly) or (goal=nil) or(target_butterfly=nil)){
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
					add k to: dup_next_cell;
				}
			}
		}
		list<cell>target <- dup_next_cell where(!(empty(butterfly inside each)));
		int color_dominant <- get_most_color();
		// extension 1: hunt the most dominant color 
		
		list<butterfly>butterflies;
		loop t over:target{
			if length(butterfly inside t)>0{
				add (butterfly inside t)[0] to: butterflies;
			}	
		} 
		butterflies <- butterflies where (each.red=color_dominant);
		
		if (length(butterflies)>0){
			butterflies <- shuffle(butterflies);
			target_butterfly <- first(butterflies);
			source <- my_cell.location;
			goal <-target_butterfly.my_cell.location;
		}

	}
	
	reflex move{
		if (goal !=nil and target_butterfly!=nil and !dead(target_butterfly)){
			source <- my_cell.location;
			goal <-target_butterfly.my_cell.location;
			using topology(cell) {
				the_path <- path_between((cell as_map (each::each.grid_value)), source, goal);
				x <- point(the_path.vertices at 1).x;
				y <- point(the_path.vertices at 1).y;
				
			}
		}
		list<cell> next_cell1 <- my_cell.neighbors where(empty(predator inside each));

		if (target_butterfly!=nil and !dead(target_butterfly)){
			list<cell>next_cell2 <- next_cell1 where(each.location.x=x and each.location.y=y);

			if (length(next_cell2)>0){
				cell next_cell <-first(next_cell2);
				list<butterfly>butterflies <-butterfly inside next_cell;
				if (length(butterflies)>0){
					if (abs(my_cell.red-butterflies[0].red) > color_threshold_camouflage
						and abs(my_cell.green-butterflies[0].green) > color_threshold_camouflage
						and abs(my_cell.blue-butterflies[0].blue) > color_threshold_camouflage){
						if (first(butterflies)=target_butterfly){
							target_butterfly<-nil;
							goal <- nil;
							x<-0.0;
							y<-0.0;
						}
						nb_dead <- nb_dead +1;
						ask butterflies{
							do die;
						}	
						
					}
					else{
						nb_times_camouflage <- nb_times_camouflage + 1;
					}
	
				}
				my_cell.is_occupied<- false;
				next_cell.is_occupied<- true;
				my_cell <- next_cell;
				location <- next_cell.location ;	
			} 
		}
		else if(target_butterfly=nil) {
			cell next_cell <- one_of(my_cell.neighbors where(empty(predator inside each)));
			list<butterfly>butterflies <-butterfly inside next_cell;
			if (length(butterflies)>0){
				if (abs(my_cell.red-butterflies[0].red) > color_threshold_camouflage
					and abs(my_cell.green-butterflies[0].green) > color_threshold_camouflage
					and abs(my_cell.blue-butterflies[0].blue) > color_threshold_camouflage){
					nb_dead <- nb_dead +1;
					ask butterflies{
						do die;
					}	
				}
				else{
					nb_times_camouflage <- nb_times_camouflage + 1;
				}
	
			}
			my_cell.is_occupied<- false;
			next_cell.is_occupied<- true;
			my_cell <- next_cell;
			location <- next_cell.location ;	
		}	

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


grid cell height:cell_height width:cell_width neighbors: neighborhood_size optimizer: algorithm{
	rgb color;
	int green;
	int blue;
	int red;
	bool is_occupied <-false;
	list<cell> neighbors  <- (self neighbors_at neighborhood_size);
	
	init{
		// init gradient environment (this code can adapt to any cell_width, cell_height)
		int color_value <- int((location.x-50/cell_width)/(100/cell_width)*color_increment);
		red <- color_value;
		green <- color_value;
		blue <- color_value;	
		color <-rgb(red, green, blue, 255);
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
				data "number_of_all_butterflies" value: nb_butterfly color: #purple;
				
			}
		}
		monitor "Number of butterfly" value: nb_butterfly;
		monitor "Number of times camouflage" value: nb_times_camouflage;
		monitor "Number of dead butterfly" value: nb_dead;
		monitor "Number of born butterfly" value: nb_born;
		monitor "Number of white butterfly" value: nb_butterfly_white;
		monitor "Number of black butterfly" value: nb_butterfly_black;
		monitor "Number of gray butterfly" value: nb_butterfly_gray;
		monitor "Number of predators" value: nb_predator;
	}
}
