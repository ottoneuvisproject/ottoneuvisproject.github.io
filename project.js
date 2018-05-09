// Created the SVG in index.html

// Set the dimensions and margins of the graph
var svg = d3.select("svg"),
    margin = {top: 20, right: 20, bottom: 30, left: 40},
    width = +svg.attr("width") - margin.left - margin.right,
    height = +svg.attr("height") - margin.top - margin.bottom;

// Scales for the main_g
var x = d3.scaleBand().rangeRound([0, width]).padding(0.1);
var y = d3.scaleLinear().rangeRound([height, 0]); 

// Scales for the line chart
var inner_x = d3.scaleLinear().rangeRound([0, width/4]); // why "round"?
var inner_y = d3.scaleLinear().rangeRound([200, 0]); // why "round"? 

// Create main group
var main_g = svg.append("g")
		   .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

// Create line group
var line_g = svg.append("g")
		   .attr("transform", "translate(" + 500 + "," + 50 + ")"); // fix later (to be based on bar chart)

// Create line group (NEW)
var clear_button = svg.append("g")
		   .attr("transform", "translate(" + 500 + "," + 50 + ")"); // fix later (to be based on bar chart)

// Data structures
var players = [];
var teams = {};

// Click status buttons
var pos_clicked = initializePosClick();

var own_clicked = [ ["All", true], ["Free Agent", false], ["Owned", false]];

// All possible positions
var positions = ["sp", "rp", "c", "first", "second", "third", "shortstop", "outfield", "util"];


// Tooltips
var div = d3.select("body").append("div")
			.attr("class","tooltip")
			.style("opacity",0);


// Read in data, populate data structures, call viz.
d3.csv("toUse_01.csv", function(error, data) {

	if (error) {throw error};

	// sort by fpts_avg
	data.sort(function(a,b){
		return b.fpts_avg - a.fpts_avg;
	});

	data.forEach(function(d) {

		// create player object & associated attributes
		var player = {
			name: d.name,
			playerid: d.playerid,
			fpts_avg: +d.fpts_avg,
			fpts_steamer: +d.fpts_steamer,
			fpts_thebat: +d.fpts_thebat,
			fpts_steamer600: +d.fpts_steamer600,
			fpts_zips: +d.fpts_zips,
			fpts_atc: +d.fpts_atc,
			fpts_depthcharts: +d.fpts_depthCharts,
			fpts_hist: [[2010, +d.fpts10], [2011, +d.fpts11], [2012, +d.fpts12], [2013, +d.fpts13], [2014, +d.fpts14], [2015, +d.fpts15], [2016, +d.fpts16], [2017, +d.fpts17]],
			fpts_proj: [ [ [2017, +d.fpts17], [2018, +d.fpts_steamer] ], [ [2017, +d.fpts17], [2018, +d.fpts_depthCharts] ], [ [2017, +d.fpts17], [2018, +d.fpts_steamer600] ], [ [2017, +d.fpts17], [2018, +d.fpts_zips] ], [ [2017, +d.fpts17], [2018, +d.fpts_atc] ], [ [2017, +d.fpts17], [2018, +d.fpts_thebat] ], ],
			mlbTeam: d.team,
			fantasyTeam: d.fantasyteam,
			salary: +d.salary,
			own: +d.ownpercentage, 
			avgSalary: +d.avgsalary,
			isPitcher: +d.ispitcher,
			sp: +d.sp,
			rp: +d.rp,
			c: +d.catcher,
			first: +d.first,
			second: +d.second, 
			third: +d.third, 
			shortstop: +d.short,
			outfield: +d.outfield,
			util: +d.utility,
			displayed: 1, 
			clicked: false
		};

		players.push(player); // add player to array of players

		// Create new dict that holds fantasy team -> player pairs
		if (!(player.fantasyTeam in teams)) {
			teams[player.fantasyTeam] = {};
			for(var i = 0; i < positions.length; i++){
				teams[player.fantasyTeam][positions[i]] = [];
			}
		} 

		// Add players to fantasy teams based on their position(s)
		for (i in positions) {
			if (player[positions[i]] == 1) {
				teams[player.fantasyTeam][positions[i]].push(player);
			}
		}
	})

	// set bar chart domain ("playerid")
	x.domain(data.map(function(d) {
		return d.playerid;
	}));

	// set bar chart domain ("fpts")
	y.domain([0,
		d3.max(players, function(d) {
			return d.fpts_avg;
		})
	]);

	// set line chart domain (2010 - 2018)
	inner_x.domain([2010, 2018]);

	// set line chart domain ("fpts_avg")
	inner_y.domain([0, 1500]);

	// Create everything
	restoreLineChart();
	createBarChart();
	createOwnershipFilter(); 
	createPositionalFilter();

});

function createBarChart() {

	// Create axes
	main_g.append("g")
	 .attr("class", "axis axis--x")
	 .attr("transform", "translate(0," + height + ")")
	 .call(d3.axisBottom(x).tickValues([])) // create x-axis
	 .append("text")
	 .attr("transform", "translate(0," + height + ")")
	 .attr("fill", "black")
	 .style("text-anchor","middle")
	 .text("Player"); // TODO: doesn't work

	main_g.append("g")
	 .attr("class", "axis axis--y") 
     .call(d3.axisLeft(y).ticks(10)) // create y-axis
     .append("text")
     .attr("transform", "rotate(-90)")
     .attr("y", 6)
     .attr("dy", "0.71em")
     .attr("fill", "black")
     .text("Projected Fantasy Points");

	// Create bars
	main_g.selectAll(".bar")
	 .data(players)
	 .enter()
	 .append("rect")
	 .attr("class", "bar")
     .attr("x", function(d) { return x(d.playerid); })
     .attr("y", function(d) { return y(d.fpts_avg); })
     .attr("width", x.bandwidth())
     .attr("height", function(d) { return height - y(d.fpts_avg); })
     .on("click",function(d){ // Make line chart
     	d.clicked = true;
     	if (d.displayed == 1) {
     		//restoreLineChart(); // TODO: keep this? Or enable multiple players to be clicked? 
     		draw([d]); // Draw the line chart associated with the player
     		restoreBars(false);
     	}
     })
     .on("mouseover",function(d){
		// Tooltips
	     if(d.displayed == 1) {	
	     	div.transition()
	     		.duration(0)
	     		.style("opacity",.9);
	     	div.html("<b>" + d.name+ "</b>" + "</br>" + d.fpts_avg + "</br>" + d.fantasyTeam)
	     		.style("left",(d3.event.clientX)+"px")
	     		.style("top", (d3.event.clientY - 50) + "px");

	     	d3.select(this)
	     		.style("fill", "white");	
     	} 

     })
     .on("mouseout",function(d){

     	// Tooltips
	    if(d.displayed==1) {

		    div.transition()
		    	.duration(0)
		     	.style("opacity",0);

		    restoreBars(false);
	     }
    })

    restoreBars(false);
}

// get RGB value associated with ownership status
function getOwnershipColor(status, shaded) {
	if (!shaded) {
		if (status === "All") {
	  		return "white";
  		}
  		if (status === "Free Agent") {
  			return d3.rgb(245, 206, 148);
  		}
  		if (status == "Owned") {
  			return d3.rgb(94, 157, 120); 
			}
	} else {
		if (status === "All") {
	  		return d3.rgb(220, 220, 220);
  		}
  		if (status === "Free Agent") {
  			return d3.rgb(195, 156, 98);
  		}
  		if (status == "Owned") {
  			return d3.rgb(44, 107, 70); 
			}
	}
}

// TODO: clean this logic up (?)
function resetOwnershipButtons(clickedButton) {

	// remove everything in main_g
	main_g.selectAll("*").remove();

	// Unclick all buttons
	own_clicked[0][1] = false;
	own_clicked[1][1] = false;
	own_clicked[2][1] = false;

	// Only click button of passed in parameter
	if (clickedButton === "All") {
		own_clicked[0][1] = true;
	}
	if (clickedButton === "Free Agent") {
		own_clicked[1][1] = true;
	}
	if (clickedButton === "Owned") {
		own_clicked[2][1] = true;
	}
	
	// recreate 
	createOwnershipFilter();
	createPositionalFilter();
	createBarChart();
	restoreBars(false);
}

function createOwnershipFilter() {

	// Add clickable circle
	main_g.selectAll("circle_ownership")
			.data(own_clicked)
			.enter()
			.append("circle")
			.attr("class", "circle_ownership")
		  	.attr("cx", 150)
		  	.attr("cy", function(d, i) {
		  		return 68 + i * 37;
		  	})
		  	.attr("r", 12)
		  	.attr("fill", function(d) {
		  		if (d[1] == true) {
		  			return getOwnershipColor(d[0], true);
		  		} else {
		  			return getOwnershipColor(d[0], false);
		  		}
		  	})
		  	.attr("stroke-width", function(d) {
		  		if (d[0] == "All") { // add outline to only white circle
		  			return 0.6;
		  		} else{
		  			return 0;
		  		}
		  	})
		  	.attr("stroke", "black")
		  	.on("click", function(d) {

		  		// Unclick all other buttons
		  		resetOwnershipButtons(d[0]);

		  		// Darken circle color
		  		d3.select(this).style("fill", function(d) {
		  			return getOwnershipColor(d[0], true);
		  		});

		  		restoreBars(false);
		  	})
		  	.on("mouseover", function(d) {
		  		// darken color
		  		if (!d[1]) { // if the button isn't clicked
		  			d3.select(this).style("fill", function(d) {
		  				return getOwnershipColor(d[0], true);
		  			})
		  		}
		  	})
		  	.on("mouseout", function(d) {
		  		// go back to orginal color
		  		if (!d[1]) {
		  			d3.select(this).style("fill", function(d) {
		  				return getOwnershipColor(d[0], false);
		  			})
		  		}
		  	});


	main_g.selectAll("text_ownership")
		  .data(own_clicked)
		  .enter()
		  .append("text")
		  .attr("class", "text_ownership")
		  .attr("x", 170)
		  .attr("y", function(d, i) {
		  	 	return 74 + i * 37;
		  })
		  .style("font", "16px sans-serif")
		  .text(function(d) {
		  	 	return d[0];
		  })
		  .attr("fill", function(d) {
		  		if (d[0] == "All") { // special case for all because circle fill (white) differs from font color (black)
		  			return "black";
		  		} else {
		  			return getOwnershipColor(d[0], false);
		  		}
		  });
}

function resetPositionalButtons() {

	// remove everything in main_g
	main_g.selectAll("*").remove();

	// recreate
	createOwnershipFilter();
	createPositionalFilter();
	createBarChart();
	restoreBars(false);
}

function initializePosClick() {
	// to store whether the positions are clicked or not
	var pos_clicked = [];
	var positions_abbr = ["SP", "RP", "C", "1B", "2B", "3B", "SS", "OF", "U"];
	var positions = ["sp", "rp", "c", "first", "second", "third", "shortstop", "outfield", "util"];

	// initialize all positions to clicked. 
	for (i in positions_abbr) {
		pos_clicked[i] = [positions_abbr[i], false, positions[i]]; // ["3B", displayed = false, "third"]
	}

	return pos_clicked;
}

function createPositionalFilter() {

	// make circle
	main_g.selectAll("circle_positional")
		.data(pos_clicked)
		.enter()
		.append("circle")
		.attr("class", "circle_positional")
		.attr("cy", function(d, i) {
			return(40 + i * 20);
		})
		.attr("cx", 330)
		.attr("r", 8)
		.attr("fill", function(d) {
			if (d[1]) {
				d3.select(this).style("fill", "black");
			} else {
				d3.select(this).style("fill", "white");
			}
			makePositionalTitles();
		})
		.attr("stroke-width", .7)
		.attr("stroke", "black")
		.on("mouseover", function(d) {
			d3.select(this).style("fill", d3.rgb(220, 220, 220));
			makePositionalTitles();
		})
		.on("mouseout", function(d) {
			if (d[1]) {
				d3.select(this).style("fill", "black");
			} else {
				d3.select(this).style("fill", "white");
			}
			makePositionalTitles();
		})
		.on("click", function(d) {

			d[1] = !d[1];
		 	if (d[1]) {
		 		// flip the colors
		 		d3.select(this).style("fill", "black");
		 		makePositionalTitles();
		 	} else {
		 		// flip the colors
		 		d3.select(this).style("fill", "white");
		 		makePositionalTitles();
		 	}

		 	restoreBars(false);
		});

	makePositionalTitles();
}

// Necessary to be separate in order to switch color on click
function makePositionalTitles() {
	main_g.selectAll("pos_title")
		.data(pos_clicked)
		.enter()
		.append("text")
		.attr("class", "pos_title")
		.attr("x", 330)
		.attr("y", function(d, i) {
			return(40 + i * 20 + 3);
		})
		.style("font", "8px sans-serif")
		.attr("text-anchor", "middle")
		.attr("fill", function(d) {
			if (d[1]) {
				return "white";
			} else {
				return "black";
			}
		})
		.text(function(d) {
			return d[0];
		});
}

function restoreLineChart() {
	line_g.selectAll("*").remove();
	
	// Create axes
	line_g.append("g")
	 .attr("class", "axis axis--x")
	 .attr("transform", "translate(0," + 200 + ")")
	 .call(d3.axisBottom(inner_x).tickFormat(d3.format("d")))
	 .append("text")
     .attr("y", 22)
     .attr("x", 325)
     .attr("dy", "0.71em")
     .attr("fill", "#000")
     .text("Year");
	 
	line_g.append("g")
	 .attr("class", "axis axis--y") 
     .call(d3.axisLeft(inner_y).ticks(10))
     .append("text")
     .attr("transform", "rotate(-90)")
     .attr("y", 6)
     .attr("dy", "0.71em")
     .attr("fill", "#000")
     .text("Fantasy Points");

    drawClearButton();

	restoreBars(false);
}

// Draw line chart

// PARAMETERS: playersToDraw is an array of player objects 
function draw(playersToDraw) {

	// Create axes
	line_g.append("g")
	 .attr("class", "axis axis--x")
	 .attr("transform", "translate(0," + 200 + ")")
	 .call(d3.axisBottom(inner_x).tickFormat(d3.format("d")))
	 .append("text")
     .attr("y", 22)
     .attr("x", 325)
     .attr("dy", "0.71em")
     .attr("fill", "#000")
     .text("Year");
	 
	line_g.append("g")
	 .attr("class", "axis axis--y") 
     .call(d3.axisLeft(inner_y).ticks(10))
     .append("text")
     .attr("transform", "rotate(-90)")
     .attr("y", 6)
     .attr("dy", "0.71em")
     .attr("fill", "#000")
     .text("Fantasy Points");

    var drawLine = d3.line()
	    			 .x(function(d) { // d here being [ [2010, fpts_2010], [2011, fpts_2011], ...]
	    			 	return inner_x(d[0]); // Year [2010, 2011...]
	    			 })
	    			 .y(function(d) {
	    			 	return inner_y(d[1]); // FPts [fpts_10, fpts_11, ...]
	    			 });


	var hist_lines = line_g.selectAll("hist_line")
				      .data(playersToDraw)
				      .enter()
				      .append("g")
				      .attr("class", "hist_line");

	// Draw the "history" line
	hist_lines.append("path")
		.attr("class", "line")
		.attr("fill", "none")
		.attr("d", function(d) {
			if (d != null) {
				return drawLine(d.fpts_hist);
			}
		})
		.style("stroke", function(d) {

			if (d != null) {
				if (d.fantasyTeam == "Free Agent") {
	   				return d3.rgb(245, 206, 148);
		   		} else {
		   			return d3.rgb(94, 157, 120);
		   		}
			}

	     })
   		.style("stroke-width", "1.5px");

   // draw the projected lines of each player
   for (i in playersToDraw) {
   		if (playersToDraw[i] != null) {
   			var currentPlayer = playersToDraw[i];

		    var proj_lines = line_g.selectAll("proj_line")
						  .data(playersToDraw[i].fpts_proj)
						  .enter()
						  .append("g")
						  .attr("class", "proj_line");

	   		proj_lines.append("path")
	  			 .attr("class", "line")
	  			 .attr("fill", "none")
	  			 .attr("d", function(d) {
	  			 	if (d != null) {
						return drawLine(d); // [ [2017, fpts_17], [2018, fpts_ZIPS] ]
					}
	  			 })
	  			 .style("stroke-dasharray", ("3, 3"))
	    		 .style("stroke", function(d) {
			     		if (currentPlayer.fantasyTeam == "Free Agent") {
				   			return d3.rgb(245, 206, 148);
				   		} else {
				   			return d3.rgb(94, 157, 120);
				   		}
			     	})
		   		 .style("stroke-width", "1.5px");

		   	line_g.append("text")
			    .attr("y", inner_y(currentPlayer.fpts_avg) - 5)
			    .attr("x", 345)
			    .attr("dy", "0.71em")
			    .style("font", "10px sans-serif")
			    .attr("fill", function(d) {
			    	if (currentPlayer.fantasyTeam == "Free Agent") {
				   		return d3.rgb(245, 206, 148);
				   	} else {
				   		return d3.rgb(94, 157, 120);
				   	}
			    })
			    .text(currentPlayer.name);
   		}
   }		
}

// function draw
function drawClearButton() {
	// Draw erase button
    clear_button.selectAll("circle_clear")
    			.data([1])
				.enter()
				.append("circle")
				.attr("class", "circle_clear")
			  	.attr("cx", 175)
			  	.attr("cy", 250)
			  	.attr("r", 15)
			  	.attr("stroke-width", 1)
			  	.attr("stroke", "black")
			  	.attr("fill", "white")
			  	.on("click", function(d) {
			  		restoreBars(true);
			  		restoreLineChart();			  		
			  	});

	clear_button.append("text")
				.attr("class", "clear_text")
				.attr("x", 175)
				.attr("y", 254)
				.style("font", "10px sans-serif")
				.attr("text-anchor", "middle")
				.text("clear")
				.on("click", function(d) {
			  		restoreBars(true);
			  		restoreLineChart();			  		
			  	});
}


function restoreBars(unclickAll) {
	svg.selectAll("rect")
	   .data(players)
	   .style("fill", function(d) {

	   		// for a total reset
	   		if (unclickAll) {
	   			d.clicked = false; 
	   		}

	   		if (d.clicked) { // if the player's line graph is displayed
	   			return "yellow";

	   		} else {

	   			if (positionEligible(d)) { // if the player is eligible based on position

	   				if (own_clicked[1][1]) { // if "Free Agent" button is clicked
		   				if (d.fantasyTeam === "Free Agent") {
				   			d.displayed = 1;
						   	return d3.rgb(245, 206, 148);
				   		} else {
				   			d.displayed = 0;
				   			return d3.rgb(245, 245, 245);
				   		}
		   			}
		   			if (own_clicked[2][1]) { // if "Owned" button is clicked
		   				if (d.fantasyTeam === "Free Agent") {
				   			d.displayed = 0;
				   			return d3.rgb(245, 245, 245);
				   		} else {
				   			d.displayed = 1;
						   	return d3.rgb(94, 157, 120);
						}
		   			}
		   			if (own_clicked[0][1]) { // if "All" button is clicked
		   				d.displayed = 1; 
		   				if (d.fantasyTeam == "Free Agent") {
						   	return d3.rgb(245, 206, 148);
						} else {
						   	return d3.rgb(94, 157, 120);
						}
		   			}
		   		} else {
		   			d.displayed = 0;
				   	return d3.rgb(245, 245, 245);
		   		}
	   		}

	   });
}

// LISTENER (recommendation)
d3.select("#recommender")
	.on("change",function(){
		var selected = document.getElementById("recommender");
		var team = selected.options[selected.selectedIndex].value;
		if (team != "Free Agent") {

			// should just be player objects! 
			var rec = getRecommendation(team)["player"];
			var inc = getRecommendation(team)["incumbent"]; // sometimes null

			restoreLineChart(); // erase the previous to prevent pile-up

			draw([rec, inc]);

			if (inc != null) {
				highlightPlayer(true, rec.name.toLowerCase(), inc.name.toLowerCase());
			} else {
				highlightPlayer(true, rec.name.toLowerCase()); // just highlight recommended player
			}
			
		} else {
			restoreLineChart(); // TODO: Keep this? 
			restoreBars(false);
		}
	})

// LISTENER (searching)
d3.select("#searchInput")
	.on("change", function(){
		var query = document.getElementById("searchInput").value.toLowerCase();
		getPlayerInfo(query);
	})

// Get what ownership button is clicked 
function getOwnershipStatus() {
	var own_status;

	if (own_clicked[0][1]) {
		own_status = "All";
	}

	if (own_clicked[1][1]) {
		own_status = "Free Agent";
	}

	if (own_clicked[2][1]) {
		own_status = "Owned";
	}

	return own_status;
}

// enter a player & see whether or not to display him based on the positional buttons clicked. 
function positionEligible(player) {

	var eligible = false;

	var no_boxes_checked = true;

	for (i in pos_clicked) {
		if (pos_clicked[i][1]) {
			no_boxes_checked = false;
			break;
		}
	}

	if (no_boxes_checked) { // then all positions are available. 
		eligible = true; 
	} else {
		for (i in pos_clicked) { // for each possible position
	   		if (pos_clicked[i][1] == true && player[pos_clicked[i][2]] == 1) {
	   			eligible = true;
	   		}
		}
	}

	return eligible;
}

// Get top players of a given team at each position
function getCurrentTops(fantasyTeam) {

	var top_by_pos = {} // array of top players by position

	for (i in positions) {
		top_by_pos[positions[i]] = null;
		try { // make sure the team has the position
			top_by_pos[positions[i]] = teams[fantasyTeam][positions[i]].sort(function(a, b) {return b.fpts_avg - a.fpts_avg})[0]; // get best sp
		} catch (error) {
			console.log(error); // log
		}
	}

	return top_by_pos;
}

// get all free agents
function getFreeAgents() {

	var fa = [];

	var itr = 0; 
	for (i in players) {
		if (players[i].fantasyTeam === "Free Agent") {
			fa[itr] = players[i];
			itr++; 
		}
	}
	return fa;
}

// get top = {"player", "recommended"}
function getRecommendation(fantasyTeam) {
	var incumbents = getCurrentTops(fantasyTeam);
	var fa = getFreeAgents();

	var top = {}; // player -> value_added

	top["player"] = players[1317]; // Taylor Davis, the 1317th player, is projected the least amount of points
	top["value_added"] = -Infinity; // set the default to no value added

	top["incumbent"] = null;

	for (i in fa) { // for each free agent

		for (j in positions) { // for each position

			if (fa[i][positions[j]] == 1) { // check if he is eligible for the position

				var upgrade = fa[i].fpts_avg;
				var current = 0;

				if (incumbents[positions[j]] != null) {
					current = incumbents[positions[j]].fpts_avg;
				}

				var diff = upgrade - current; 

				if (diff > top.value_added) {
					top["player"] = fa[i];
					top["value_added"] = diff;
					top["incumbent"] = incumbents[positions[j]];
				}
			}
		}
	}

	return(top);
}

// Draw & Highlight
function getPlayerInfo(playerName) {
	var found = false;
	var p = null; 
	for (i in players) {
		if (playerName === players[i].name.toLowerCase()) {
			p = players[i];
			var found = true;
			break; 
		}
	}
	if (found) {
		draw([p]);
	}
	highlightPlayer(found, playerName);
}

// highlights that specific players
function highlightPlayer(found, upgrade, incumbent) {
	// highlight player
	if (found) {
		svg.selectAll("rect")
		   .data(players)
		   .style("fill", function(d) {
		   		if (d.name.toLowerCase() === upgrade || d.name.toLowerCase() === incumbent) {
		   			d.clicked = true; 
				   	return "yellow";
		   		}
		   		else {
		   			if (own_clicked[1][1]) { // just free agents
		   				if (d.fantasyTeam === "Free Agent") {
				   			d.displayed = 1; 
						   	return d3.rgb(245, 206, 148);
				   		} else {
				   			d.displayed = 0;
				   			return d3.rgb(245, 245, 245);
				   		}
		   			}
		   			if (own_clicked[2][1]) { // just owned
		   				if (d.fantasyTeam === "Free Agent") {
				   			d.displayed = 0;
				   			return d3.rgb(245, 245, 245);
				   		} else {
				   			d.displayed = 1;
						   	return d3.rgb(94, 157, 120);
						}
		   			} 
		   			if (own_clicked[0][1]) { // all clicked
		   				if (d.fantasyTeam == "Free Agent") {
						   	return d3.rgb(245, 206, 148);
						} else {
						   	return d3.rgb(94, 157, 120);
						}
					}
		   		}
		   });
	} else { // reset back to original color scheme
		restoreBars(false);
	}
}