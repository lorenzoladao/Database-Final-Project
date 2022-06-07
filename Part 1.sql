/*1*/
/*
ID, precinct -> state, locality, geo
timestamp, precinct -> totalvotes, biden, trump
*/

/*2*/
create table Precincts(
	ID int,
    precinct char(255) primary key,
    state char(255),
    locality char(255),
    geo char(255) not null
    ) select ID, precinct, state, locality, geo from penna group by precinct;
    
create table Votes(
	timestamp timestamp,
    precinct char(255),
    totalvotes int,
    biden int,
    trump int,
    constraint pk_Votes primary key (timestamp, precinct)
    ) select timestamp, precinct, totalvotes, biden, trump from penna group by timestamp, precinct;
