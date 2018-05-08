# Set the working directory
##setwd("Desktop/Life/USF/Classes/2017-2018/Spring/Data Visualization/Project/Data")
setwd("Users/Aren/Documents/Projections")

# .................. Projections .......................

# Read in projection data
##batters <- read.csv("../Data/Projections/Batters/Depth Charts (Batters).csv")
##pitchers <- read.csv("../Data/Projections/Pitchers/Depth Charts (Pitchers).csv")

## ZIPS
##batters <- read.csv("zips_batters_clean.csv")
##pitchers <- read.csv("zips_pitchers_clean.csv")

## TheBat
##batters <- read.csv("thebat_batters_clean.csv")
##pitchers <- read.csv("thebat_pitchers_clean.csv")
##names(batters) <- c("playerid","HBP","AB","H","X2B","X3B","HR","BB","SB","CS")

##Steamer
##batters <- read.csv("steamer_batters_clean.csv")
##pitchers <- read.csv("steamer_pitchers_clean.csv")

##Steamer600
##batters <- read.csv("steamer600_hitters_clean.csv")
##pitchers <- read.csv("steamer600_pitchers_clean.csv")

##Fans
##batters <- read.csv("fans_batters_clean.csv")
##pitchers <- read.csv("fans_pitchers_clean.csv")

##ATC
batters <- read.csv("atc_batters_clean.csv")
pitchers <- read.csv("atc_pitchers_clean.csv")
names(batters) <- c("playerid","HBP","AB","H","X2B","X3B","HR","BB","SB","CS")


# Calculate *batter* fantasy points & add as a column
batters$FPts <- (-1 * batters$AB) + (5.6 * batters$H) + (2.9 * batters$X2B) + (5.7 * batters$X3B) + (9.4 * batters$HR) + (3 * batters$BB) + (3 * batters$HBP) + (1.9 * batters$SB) + (-2.8 * batters$CS)

# Since HBP isn't projected for pitchers, we'll to approximate
# According to teamrankings.com, the average MLB HBP/Game hovers around .5
# It follows that:
hbp_per_ip <- .5 / 9 # batters hit on average per inning
pitchers$HBP <- round(pitchers$ip * hbp_per_ip) # add column

# Calculate *pitcher* fantasy points & add as a column
pitchers$FPts <- (7.4 * pitchers$ip) + (2 * pitchers$so) + (-2.6 * pitchers$h) + (-3 * pitchers$bb) + (-3 * pitchers$HBP) + (-12.3 * pitchers$hr) + (5 * pitchers$sv) + (4 * pitchers$hld)

# Extract only the information we need from *pitchers*
pitchers_clean <- data.frame(pitchers$playerid, pitchers$FPts)
names(pitchers_clean) <- c("playerid", "FPtsProj")

# Extract only the information we need from *batters*
batters_clean <- data.frame(batters$playerid, batters$FPts)
names(batters_clean) <- c("playerid", "FPtsProj")

# Combine pitchers & hitters into one data frame
combined <- as.data.frame(rbind(batters_clean, pitchers_clean))

# If team == "" , set value to "FA/Prospect"
combined$Team <- as.character(combined$Team) # first, convert from categorical to character to avoid pesky factor levels (as they won't matter in this context)
combined[which(combined$Team == ""),]$Team <- "FA/Prospect"

# Export to CSV
write.csv(x = combined, "atc_projections.csv")

# .............................Average Valuess......................................

# Read in data
avg_values <- read.csv("AverageValues.csv")

# Convert column types to character to avoid strange coersion happenings
avg_values$Name <- as.character(avg_values$Name)
avg_values$FG.MajorLeagueID <- as.character(avg_values$FG.MajorLeagueID)
avg_values$FG.MinorLeagueID <- as.character(avg_values$FG.MinorLeagueID)

# Special case of missing data 
avg_values[1052, ]$FG.MinorLeagueID = "sa829855"

# replace "N/A" player ids with minor league player ids
for (i in 1:nrow(avg_values)) {
  if (is.na(avg_values[i,]$FG.MajorLeagueID)) {
    avg_values[i,]$FG.MajorLeagueID <- avg_values[i,]$FG.MinorLeagueID
  }
}

# Is the player a pitcher? 1B? 2B? ... (initialize to a vector of n zeros to add to df)
pitcher <- integer(nrow(avg_values))
sp <- integer(nrow(avg_values)) # starting pitcher
rp <- integer(nrow(avg_values)) # relief pitcher
catcher <- integer(nrow(avg_values))
first <- integer(nrow(avg_values))
second <- integer(nrow(avg_values))
third <- integer(nrow(avg_values))
short <- integer(nrow(avg_values))
outfield <- integer(nrow(avg_values))
utility <- integer(nrow(avg_values))

av <- data.frame(avg_values$Name, avg_values$FG.MajorLeagueID, avg_values$Own., avg_values$Avg.Salary, avg_values$Position.s., pitcher, sp, rp, catcher, first, second, third, short, outfield, utility)
names(av) <- c("Name", "playerid", "ownPercentage", "avgSalary", "position", "isPitcher", "sp", "rp", "catcher", "first", "second", "third", "short", "outfield", "utility")

# Make name & position of type character, not factor. 
av$name <- as.character(av$name)
av$position <- as.character(av$position)

i <- 1
for (pos in av$position) {
  if (grepl("RP", pos) || grepl("SP", pos)) { # if the player is eligible as a starting pitcher (SP) or relief pitcher (RP)
    av[i, 6] <- 1
  }
  if (grepl("SP", pos)) {
    av[i, 7] <- 1
  }
  if (grepl("RP", pos)) {
    av[i, 8] <- 1
  }
  if (grepl("C", pos)) {
    av[i, 9] <- 1
    av[i, 15] <- 1 # all hitters are eligible for the UTIL spot
  }
  if (grepl("1B", pos)) {
    av[i, 10] <- 1
    av[i, 15] <- 1
  }
  if (grepl("2B", pos)) {
    av[i, 11] <- 1
    av[i, 15] <- 1
  }
  if (grepl("3B", pos)) {
    av[i, 12] <- 1
    av[i, 15] <- 1
  }
  if (grepl("SS", pos)) {
    av[i, 13] <- 1
    av[i, 15] <- 1
  }
  if (grepl("OF", pos)) {
    av[i, 14] <- 1
    av[i, 15] <- 1
  }
  if (grepl("UTIL", pos)) {
    av[i, 15] <- 1
  }
  i <- i + 1
}

# Take out the "$" from the average values
av$avgSalary <- sub(pattern = "[^0-9]", x = av$avgSalary, replacement = "")

write.csv(x = av, "avg_values_with_ids_1.csv")

# ............................... Clean Rosters............................
rosters <- read.csv("LeagueRosters.csv")

# Convert column types to character to avoid strange coersion happenings
rosters$Name <- as.character(rosters$Name)
rosters$FG.MajorLeagueID <- as.character(rosters$FG.MajorLeagueID)
rosters$FG.MinorLeagueID <- as.character(rosters$FG.MinorLeagueID)

# replace "N/A" player ids with minor league player ids
for (i in 1:nrow(rosters)) {
  if (is.na(rosters[i,]$FG.MajorLeagueID)) {
    rosters[i,]$FG.MajorLeagueID <- rosters[i,]$FG.MinorLeagueID
  }
}

# factor -> character
rosters$Team.Name <- as.character(rosters$Team.Name)

i <- 1
# Clean specific team names
for (team in rosters$Team.Name) {
  rosters[i, 2] <- sub(pattern = "[',]+", x = team, replacement = "") # Make more general for Emojis
  i <- i+1
}

r <- data.frame(rosters$Name, rosters$FG.MajorLeagueID, rosters$Team.Name, rosters$Salary)
names(r) <- c("Name", "playerid", "FantasyTeam", "Salary")

# Take the dollar sign out of player salary
r$Salary <- sub(pattern = "[^0-9]", x = r$Salary, replacement = "")

write.csv(x = r, "rosters_with_ids.csv")

#............... combined in SQL............................

#data <- read.csv("combined_01.csv")


# .................. Historical Data ......................

# Set working directory
setwd("Desktop/Life/USF/Classes/2017-2018/Spring/Data Visualization/Project/Data/Historical/")

# Read in data 
p10 <- read.csv(file = "pitchers_10.csv")
p11 <- read.csv(file = "pitchers_11.csv")
p12 <- read.csv(file = "pitchers_12.csv")
p13 <- read.csv(file = "pitchers_13.csv")
p14 <- read.csv(file = "pitchers_14.csv")
p15 <- read.csv(file = "pitchers_15.csv")
p16 <- read.csv(file = "pitchers_16.csv")
p17 <- read.csv(file = "pitchers_17.csv")
h10 <- read.csv(file = "batters_10.csv")
h11 <- read.csv(file = "batters_11.csv")
h12 <- read.csv(file = "batters_12.csv")
h13 <- read.csv(file = "batters_13.csv")
h14 <- read.csv(file = "batters_14.csv")
h15 <- read.csv(file = "batters_15.csv")
h16 <- read.csv(file = "batters_16.csv")
h17 <- read.csv(file = "batters_17.csv")


# Calculate fantasy points
h10$FPts <- (-1 * h10$AB) + (5.6 * h10$H) + (2.9 * h10$X2B) + (5.7 * h10$X3B) + (9.4 * h10$HR) + (3 * h10$BB) + (3 * h10$HBP) + (1.9 * h10$SB) + (-2.8 * h10$CS)
h11$FPts <- (-1 * h11$AB) + (5.6 * h11$H) + (2.9 * h11$X2B) + (5.7 * h11$X3B) + (9.4 * h11$HR) + (3 * h11$BB) + (3 * h11$HBP) + (1.9 * h11$SB) + (-2.8 * h11$CS)
h12$FPts <- (-1 * h12$AB) + (5.6 * h12$H) + (2.9 * h12$X2B) + (5.7 * h12$X3B) + (9.4 * h12$HR) + (3 * h12$BB) + (3 * h12$HBP) + (1.9 * h12$SB) + (-2.8 * h12$CS)
h13$FPts <- (-1 * h13$AB) + (5.6 * h13$H) + (2.9 * h13$X2B) + (5.7 * h13$X3B) + (9.4 * h13$HR) + (3 * h13$BB) + (3 * h13$HBP) + (1.9 * h13$SB) + (-2.8 * h13$CS)
h14$FPts <- (-1 * h14$AB) + (5.6 * h14$H) + (2.9 * h14$X2B) + (5.7 * h14$X3B) + (9.4 * h14$HR) + (3 * h14$BB) + (3 * h14$HBP) + (1.9 * h14$SB) + (-2.8 * h14$CS)
h15$FPts <- (-1 * h15$AB) + (5.6 * h15$H) + (2.9 * h15$X2B) + (5.7 * h15$X3B) + (9.4 * h15$HR) + (3 * h15$BB) + (3 * h15$HBP) + (1.9 * h15$SB) + (-2.8 * h15$CS)
h16$FPts <- (-1 * h16$AB) + (5.6 * h16$H) + (2.9 * h16$X2B) + (5.7 * h16$X3B) + (9.4 * h16$HR) + (3 * h16$BB) + (3 * h16$HBP) + (1.9 * h16$SB) + (-2.8 * h16$CS)
h17$FPts <- (-1 * h17$AB) + (5.6 * h17$H) + (2.9 * h17$X2B) + (5.7 * h17$X3B) + (9.4 * h17$HR) + (3 * h17$BB) + (3 * h17$HBP) + (1.9 * h17$SB) + (-2.8 * h17$CS)

p10$FPts <- (7.4 * p10$IP) + (2 * p10$SO) + (-2.6 * p10$H) + (-3 * p10$BB) + (-3 * p10$HBP) + (-12.3 * p10$HR) + (5 * p10$SV) + (4 * p10$HLD)
p11$FPts <- (7.4 * p11$IP) + (2 * p11$SO) + (-2.6 * p11$H) + (-3 * p11$BB) + (-3 * p11$HBP) + (-12.3 * p11$HR) + (5 * p11$SV) + (4 * p11$HLD)
p12$FPts <- (7.4 * p12$IP) + (2 * p12$SO) + (-2.6 * p12$H) + (-3 * p12$BB) + (-3 * p12$HBP) + (-12.3 * p12$HR) + (5 * p12$SV) + (4 * p12$HLD)
p13$FPts <- (7.4 * p13$IP) + (2 * p13$SO) + (-2.6 * p13$H) + (-3 * p13$BB) + (-3 * p13$HBP) + (-12.3 * p13$HR) + (5 * p13$SV) + (4 * p13$HLD)
p14$FPts <- (7.4 * p14$IP) + (2 * p14$SO) + (-2.6 * p14$H) + (-3 * p14$BB) + (-3 * p14$HBP) + (-12.3 * p14$HR) + (5 * p14$SV) + (4 * p14$HLD)
p15$FPts <- (7.4 * p15$IP) + (2 * p15$SO) + (-2.6 * p15$H) + (-3 * p15$BB) + (-3 * p15$HBP) + (-12.3 * p15$HR) + (5 * p15$SV) + (4 * p15$HLD)
p16$FPts <- (7.4 * p16$IP) + (2 * p16$SO) + (-2.6 * p16$H) + (-3 * p16$BB) + (-3 * p16$HBP) + (-12.3 * p16$HR) + (5 * p16$SV) + (4 * p16$HLD)
p17$FPts <- (7.4 * p17$IP) + (2 * p17$SO) + (-2.6 * p17$H) + (-3 * p17$BB) + (-3 * p17$HBP) + (-12.3 * p17$HR) + (5 * p17$SV) + (4 * p17$HLD)

# Extract only the information that we need
p10_clean <- data.frame(p10$Name, p10$playerid, p10$FPts)
names(p10_clean) <- c("Name", "playerid", "FPts10")
p11_clean <- data.frame(p11$Name, p11$playerid, p11$FPts)
names(p11_clean) <- c("Name", "playerid", "FPts11")
p12_clean <- data.frame(p12$Name, p12$playerid, p12$FPts)
names(p12_clean) <- c("Name", "playerid", "FPts12")
p13_clean <- data.frame(p13$Name, p13$playerid, p13$FPts)
names(p13_clean) <- c("Name", "playerid", "FPts13")
p14_clean <- data.frame(p14$Name, p14$playerid, p14$FPts)
names(p14_clean) <- c("Name", "playerid", "FPts14")
p15_clean <- data.frame(p15$Name, p15$playerid, p15$FPts)
names(p15_clean) <- c("Name", "playerid", "FPts15")
p16_clean <- data.frame(p16$Name, p16$playerid, p16$FPts)
names(p16_clean) <- c("Name", "playerid", "FPts16")
p17_clean <- data.frame(p17$Name, p17$playerid, p17$FPts)
names(p17_clean) <- c("Name", "playerid", "FPts17")
h10_clean <- data.frame(h10$Name, h10$playerid, h10$FPts)
names(h10_clean) <- c("Name", "playerid", "FPts10")
h11_clean <- data.frame(h11$Name, h11$playerid, h11$FPts)
names(h11_clean) <- c("Name", "playerid", "FPts11")
h12_clean <- data.frame(h12$Name, h12$playerid, h12$FPts)
names(h12_clean) <- c("Name", "playerid", "FPts12")
h13_clean <- data.frame(h13$Name, h13$playerid, h13$FPts)
names(h13_clean) <- c("Name", "playerid", "FPts13")
h14_clean <- data.frame(h14$Name, h14$playerid, h14$FPts)
names(h14_clean) <- c("Name", "playerid", "FPts14")
h15_clean <- data.frame(h15$Name, h15$playerid, h15$FPts)
names(h15_clean) <- c("Name", "playerid", "FPts15")
h16_clean <- data.frame(h16$Name, h16$playerid, h16$FPts)
names(h16_clean) <- c("Name", "playerid", "FPts16")
h17_clean <- data.frame(h17$Name, h17$playerid, h17$FPts)
names(h17_clean) <- c("Name", "playerid", "FPts17")

# Combine pitchers & hitters into one data frame
comb10 <- as.data.frame(rbind(h10_clean, p10_clean))
comb11 <- as.data.frame(rbind(h11_clean, p11_clean))
comb12 <- as.data.frame(rbind(h12_clean, p12_clean))
comb13 <- as.data.frame(rbind(h13_clean, p13_clean))
comb14 <- as.data.frame(rbind(h14_clean, p14_clean))
comb15 <- as.data.frame(rbind(h15_clean, p15_clean))
comb16 <- as.data.frame(rbind(h16_clean, p16_clean))
comb17 <- as.data.frame(rbind(h17_clean, p17_clean))

# Remove duplicate players
# i.e., Pitchers who hit & Hitters who pitched are double counted when combined
  # Solution: keep the maximum FPt value when the ids are the same (not perfect, but whatever.)

###### 2010 #######
c_10 <- data.frame("Name", 3513, 1200)
names(c_10) <- c("Name", "playerid", "FPts10")
for (i in unique(comb10$playerid)) {                                        # for each unique playerid
  pair <- comb10[which(comb10$playerid == i),]                              # combine same player ids (1 xor 2)
  player <- NULL                                                            # initialize player data frame 
  if (nrow(pair) == 2) {                                                    # if there are two rows with the same id
    if (pair[1,]$FPts10 >= pair[2,]$FPts10) {                                   # if the first element of the pair has more fpts
      player <- data.frame(pair[1,]$Name, pair[1,]$playerid, pair[1,]$FPts10) # 
      names(player) <- c("Name", "playerid", "FPts10")
    } else {
      player <- data.frame(pair[2,]$Name, pair[2,]$playerid, pair[2,]$FPts10)
      names(player) <- c("Name", "playerid", "FPts10")
    }
  } else {
    player <- data.frame(pair[1,]$Name, pair[1,]$playerid, pair[1,]$FPts10)
    names(player) <- c("Name", "playerid", "FPts10")
  }
  c_10 <- rbind(c_10, player)
}
c_10 <- c_10[-1,] # remove the initial value (first row)

# double check these lengths are the same 
length(unique(comb10$playerid)) == nrow(c_10)

###### 2011 #######
c_11 <- data.frame("Name", 3513, 1200)
names(c_11) <- c("Name", "playerid", "FPts11")
for (i in unique(comb11$playerid)) {                                        # for each unique playerid
  pair <- comb11[which(comb11$playerid == i),]                              # combine same player ids (1 xor 2)
  player <- NULL                                                            # initialize player data frame 
  if (nrow(pair) == 2) {                                                    # if there are two rows with the same id
    if (pair[1,]$FPts11 >= pair[2,]$FPts11) {                                   # if the first element of the pair has more fpts
      player <- data.frame(pair[1,]$Name, pair[1,]$playerid, pair[1,]$FPts11) # 
      names(player) <- c("Name", "playerid", "FPts11")
    } else {
      player <- data.frame(pair[2,]$Name, pair[2,]$playerid, pair[2,]$FPts11)
      names(player) <- c("Name", "playerid", "FPts11")
    }
  } else {
    player <- data.frame(pair[1,]$Name, pair[1,]$playerid, pair[1,]$FPts11)
    names(player) <- c("Name", "playerid", "FPts11")
  }
  c_11 <- rbind(c_11, player)
}
c_11 <- c_11[-1,] # remove the initial value (first row)

# double check these lengths are the same 
length(unique(comb11$playerid)) == nrow(c_11)

###### 2012 #######
c_12 <- data.frame("Name", 3513, 1200)
names(c_12) <- c("Name", "playerid", "FPts12")
for (i in unique(comb12$playerid)) {                                        # for each unique playerid
  pair <- comb12[which(comb12$playerid == i),]                              # combine same player ids (1 xor 2)
  player <- NULL                                                            # initialize player data frame 
  if (nrow(pair) == 2) {                                                    # if there are two rows with the same id
    if (pair[1,]$FPts12 >= pair[2,]$FPts12) {                                   # if the first element of the pair has more fpts
      player <- data.frame(pair[1,]$Name, pair[1,]$playerid, pair[1,]$FPts12) # 
      names(player) <- c("Name", "playerid", "FPts12")
    } else {
      player <- data.frame(pair[2,]$Name, pair[2,]$playerid, pair[2,]$FPts12)
      names(player) <- c("Name", "playerid", "FPts12")
    }
  } else {
    player <- data.frame(pair[1,]$Name, pair[1,]$playerid, pair[1,]$FPts12)
    names(player) <- c("Name", "playerid", "FPts12")
  }
  c_12 <- rbind(c_12, player)
}
c_12 <- c_12[-1,] # remove the initial value (first row)

# double check these lengths are the same 
length(unique(comb12$playerid)) == nrow(c_12)

###### 2013 #######
c_13 <- data.frame("Name", 3513, 1200)
names(c_13) <- c("Name", "playerid", "FPts13")
for (i in unique(comb13$playerid)) {                                        # for each unique playerid
  pair <- comb13[which(comb13$playerid == i),]                              # combine same player ids (1 xor 2)
  player <- NULL                                                            # initialize player data frame 
  if (nrow(pair) == 2) {                                                    # if there are two rows with the same id
    if (pair[1,]$FPts13 >= pair[2,]$FPts13) {                                   # if the first element of the pair has more fpts
      player <- data.frame(pair[1,]$Name, pair[1,]$playerid, pair[1,]$FPts13) # 
      names(player) <- c("Name", "playerid", "FPts13")
    } else {
      player <- data.frame(pair[2,]$Name, pair[2,]$playerid, pair[2,]$FPts13)
      names(player) <- c("Name", "playerid", "FPts13")
    }
  } else {
    player <- data.frame(pair[1,]$Name, pair[1,]$playerid, pair[1,]$FPts13)
    names(player) <- c("Name", "playerid", "FPts13")
  }
  c_13 <- rbind(c_13, player)
}
c_13 <- c_13[-1,] # remove the initial value (first row)

# double check these lengths are the same 
length(unique(comb13$playerid)) == nrow(c_13)

###### 2014 #######
c_14 <- data.frame("Name", 3513, 1200)
names(c_14) <- c("Name", "playerid", "FPts14")
for (i in unique(comb14$playerid)) {                                        # for each unique playerid
  pair <- comb14[which(comb14$playerid == i),]                              # combine same player ids (1 xor 2)
  player <- NULL                                                            # initialize player data frame 
  if (nrow(pair) == 2) {                                                    # if there are two rows with the same id
    if (pair[1,]$FPts14 >= pair[2,]$FPts14) {                                   # if the first element of the pair has more fpts
      player <- data.frame(pair[1,]$Name, pair[1,]$playerid, pair[1,]$FPts14) # 
      names(player) <- c("Name", "playerid", "FPts14")
    } else {
      player <- data.frame(pair[2,]$Name, pair[2,]$playerid, pair[2,]$FPts14)
      names(player) <- c("Name", "playerid", "FPts14")
    }
  } else {
    player <- data.frame(pair[1,]$Name, pair[1,]$playerid, pair[1,]$FPts14)
    names(player) <- c("Name", "playerid", "FPts14")
  }
  c_14 <- rbind(c_14, player)
}
c_14 <- c_14[-1,] # remove the initial value (first row)

# double check these lengths are the same 
length(unique(comb14$playerid)) == nrow(c_14)

###### 2015 #######
c_15 <- data.frame("Name", 3513, 1200)
names(c_15) <- c("Name", "playerid", "FPts15")
for (i in unique(comb15$playerid)) {                                        # for each unique playerid
  pair <- comb15[which(comb15$playerid == i),]                              # combine same player ids (1 xor 2)
  player <- NULL                                                            # initialize player data frame 
  if (nrow(pair) == 2) {                                                    # if there are two rows with the same id
    if (pair[1,]$FPts15 >= pair[2,]$FPts15) {                                   # if the first element of the pair has more fpts
      player <- data.frame(pair[1,]$Name, pair[1,]$playerid, pair[1,]$FPts15) # 
      names(player) <- c("Name", "playerid", "FPts15")
    } else {
      player <- data.frame(pair[2,]$Name, pair[2,]$playerid, pair[2,]$FPts15)
      names(player) <- c("Name", "playerid", "FPts15")
    }
  } else {
    player <- data.frame(pair[1,]$Name, pair[1,]$playerid, pair[1,]$FPts15)
    names(player) <- c("Name", "playerid", "FPts15")
  }
  c_15 <- rbind(c_15, player)
}
c_15 <- c_15[-1,] # remove the initial value (first row)

# double check these lengths are the same 
length(unique(comb15$playerid)) == nrow(c_15)

###### 2016 #######
c_16 <- data.frame("Name", 3513, 1200)
names(c_16) <- c("Name", "playerid", "FPts16")
for (i in unique(comb16$playerid)) {                                        # for each unique playerid
  pair <- comb16[which(comb16$playerid == i),]                              # combine same player ids (1 xor 2)
  player <- NULL                                                            # initialize player data frame 
  if (nrow(pair) == 2) {                                                    # if there are two rows with the same id
    if (pair[1,]$FPts16 >= pair[2,]$FPts16) {                                   # if the first element of the pair has more fpts
      player <- data.frame(pair[1,]$Name, pair[1,]$playerid, pair[1,]$FPts16) # 
      names(player) <- c("Name", "playerid", "FPts16")
    } else {
      player <- data.frame(pair[2,]$Name, pair[2,]$playerid, pair[2,]$FPts16)
      names(player) <- c("Name", "playerid", "FPts16")
    }
  } else {
    player <- data.frame(pair[1,]$Name, pair[1,]$playerid, pair[1,]$FPts16)
    names(player) <- c("Name", "playerid", "FPts16")
  }
  c_16 <- rbind(c_16, player)
}
c_16 <- c_16[-1,] # remove the initial value (first row)

# double check these lengths are the same 
length(unique(comb16$playerid)) == nrow(c_16)

###### 2017 #######
c_17 <- data.frame("Name", 3513, 1200)
names(c_17) <- c("Name", "playerid", "FPts17")
for (i in unique(comb17$playerid)) {                                        # for each unique playerid
  pair <- comb17[which(comb17$playerid == i),]                              # combine same player ids (1 xor 2)
  player <- NULL                                                            # initialize player data frame 
  if (nrow(pair) == 2) {                                                    # if there are two rows with the same id
    if (pair[1,]$FPts17 >= pair[2,]$FPts17) {                                   # if the first element of the pair has more fpts
      player <- data.frame(pair[1,]$Name, pair[1,]$playerid, pair[1,]$FPts17) # 
      names(player) <- c("Name", "playerid", "FPts17")
    } else {
      player <- data.frame(pair[2,]$Name, pair[2,]$playerid, pair[2,]$FPts17)
      names(player) <- c("Name", "playerid", "FPts17")
    }
  } else {
    player <- data.frame(pair[1,]$Name, pair[1,]$playerid, pair[1,]$FPts17)
    names(player) <- c("Name", "playerid", "FPts17")
  }
  c_17 <- rbind(c_17, player)
}
c_17 <- c_17[-1,] # remove the initial value (first row)

# double check these lengths are the same 
length(unique(comb17$playerid)) == nrow(c_17)


# TODO: Maybe keep IP & PA in order to do stats like FPts/IP & FPts/PA
  # No. Because of the dissimilarity between PPIP & PPAB, we couldn't join the hitters & pitchers. 

# Write to CSV
write.csv(x = c_10, "2010.csv")
write.csv(x = c_11, "2011.csv")
write.csv(x = c_12, "2012.csv")
write.csv(x = c_13, "2013.csv")
write.csv(x = c_14, "2014.csv")
write.csv(x = c_15, "2015.csv")
write.csv(x = c_16, "2016.csv")
write.csv(x = c_17, "2017.csv")