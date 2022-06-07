/*1a*/
drop procedure if exists Winner;
DELIMITER //
create procedure Winner(
	in precinctName varchar(255))
    begin
		select if(a.trump > a.biden, "Trump", "Biden") as Precinct_Winner from 
        (select trump, biden, timestamp from penna
		where precinct = precinctName and Timestamp = (select max(Timestamp) from votes)) a;
end //
DELIMITER ;

call Winner("36-12");

/*1b*/
drop procedure if exists RankALL;
DELIMITER //
create procedure RankALL(
	in precinctName varchar(255))
    begin
		select RankByVotes as "Rank", precinct as Precinct from (
			select rank() over ( order by totalvotes desc) as RankByVotes, precinct
            from votes where Timestamp = (select max(Timestamp) from penna)
            ) a
            where precinct = precinctName;
end //
DELIMITER ;

call RankALL("053 CALN 3");

/*1c*/
drop procedure if exists RankCounty;
DELIMITER //
create procedure RankCounty(
	in precinctName varchar(255))
    begin
		select RankByCounty as "Rank", precinct as Precinct from (
			select rank() over ( order by a.totalvotes desc) as RankByCounty, a.precinct
            from (
				select v.totalvotes, v.precinct from penna v, (select precinct from precincts where locality = (select locality from precincts where precinct = precinctName)) locale
				where v.precinct = locale.precinct and Timestamp = (select max(Timestamp) from penna)
            ) a ) b
            where precinct = precinctName;
end //
DELIMITER ;

call RankCounty("05-28");

/*1d*/
drop procedure if exists PlotPrecinct;
DELIMITER //
create procedure PlotPrecinct(
	in precinctName varchar(255))
    begin
		select Timestamp, totalvotes, biden, trump from penna where precinct = precinctName;
	end //
DELIMITER ; 

call PlotPrecinct("Whiteley Voting Precinct");

/*1e*/
drop procedure if exists EarliestPrecinct;
DELIMITER //
create procedure EarliestPrecinct(
	in voteCount int)
    begin
    drop table if exists voteTable_one;
	create temporary table voteTable_one(
		Timestamp timestamp,
		Precinct char(255),
        totalvotes int
	) select timestamp, precinct, totalvotes from penna where totalvotes = voteCount;
	drop table if exists voteTable_two;
	create temporary table voteTable_two(
		Timestamp timestamp,
		Precinct char(255)
	) select timestamp, precinct from penna where totalvotes = voteCount;
    drop table if exists newVoteTable;
	create temporary table newVoteTable(
		timestamp timestamp,
		Precinct char(255),
        totalvotes int
	) select timestamp, precinct, totalvotes from voteTable_one where timestamp = (select min(timestamp) from (select timestamp from voteTable_two) a);
    drop table if exists newVoteTable_two;
	create temporary table newVoteTable_two(
		timestamp timestamp,
		Precinct char(255),
        totalvotes int
	) select timestamp, precinct, totalvotes from voteTable_one where timestamp = (select min(timestamp) from (select timestamp from voteTable_two) a);

    select distinct v.precinct from penna v, (select distinct precinct from newVoteTable_two) a
    where totalvotes = (
		select max(totalvotes) from (select v.totalvotes from penna v, (select distinct precinct from newVoteTable) a where v.precinct = a.precinct and v.timestamp = (select max(Timestamp) from penna)) a
    ) and v.precinct = a.precinct;

	end //
DELIMITER ;

call EarliestPrecinct(0);

/*2a*/
drop procedure if exists PrecinctsWon;
DELIMITER //
create procedure PrecinctsWon(
	in candidate varchar(255))
    begin
		if candidate like "biden" then select precinct, totalvotes, (biden - trump) as difference from penna 
			where biden > trump and timestamp = (select max(Timestamp) from penna) order by difference desc;
        elseif candidate like "trump" then select precinct, totalvotes, (trump - biden) as difference from penna 
			where biden < trump and timestamp = (select max(Timestamp) from penna) order by difference desc;
        else select "Not one of the candidates." as Error;
        end if;
	end //
DELIMITER ; 

call PrecinctsWon("Trump");

/*2b*/
drop procedure if exists PrecinctsWonCount;
DELIMITER //
create procedure PrecinctsWonCount(
	in candidate varchar(255))
    begin
		if candidate like "biden" then select count(precinct) as "Number of Precincts Won" from penna where biden > trump and timestamp = (select max(Timestamp) from penna);
        elseif candidate like "trump" then select count(precinct) as "Number of Precincts Won" from penna where biden < trump and timestamp = (select max(Timestamp) from penna);
        else select "Not one of the candidates." as Error;
        end if;
	end //
DELIMITER ; 

call PrecinctsWonCount("biden");

/*2c*/
drop procedure if exists PrecinctsFullLead;
DELIMITER //
create procedure PrecinctsFullLead(
	in candidate varchar(255))
    begin
		if candidate like "biden" then select timestamp, precinct from penna where biden > trump order by timestamp;
        elseif candidate like "trump" then select timestamp, precinct from penna where biden < trump order by timestamp;
        else select "Not one of the candidates." as Error;
        end if;
	end //
DELIMITER ; 

call PrecinctsFullLead("trump");

/*2d*/
drop procedure if exists PlotCandidate;
DELIMITER //
create procedure PlotCandidate(
	in candidate varchar(255))
    begin
    if candidate like "biden" then select timestamp, sum(biden) as "Total Votes for Biden" from penna group by timestamp;
        elseif candidate like "trump" then select timestamp, sum(trump) from penna group by timestamp;
        else select "Not one of the candidates." as Error;
        end if;
	end //
DELIMITER ; 

call PlotCandidate("biden");

/*2e*/
drop procedure if exists PrecinctsWonTownship;
DELIMITER //
create procedure PrecinctsWonTownship()
    begin
    select case
		when sum(finalBiden) > sum(finalTrump) then 'Biden'
		else 'Trump'
	end as "Winner Of Township", 
    sum(finalBiden) as "Total Biden Votes", sum(finalTrump) as "Total Trump Votes",  
    case
		when sum(finalBiden) > sum(finalTrump) then sum(finalBiden) - sum(finalTrump)
		else sum(finalTrump) - sum(finalBiden)
	end as "Difference in Votes"
	from
	(
		select precinct, max(Biden) as finalBiden, max(Trump) as finalTrump
		from Penna
		where precinct like "%Township%"
		group by precinct
		order by precinct
	) a;
	end //
DELIMITER ; 

drop procedure if exists PrecinctsWonWard;
DELIMITER //
create procedure PrecinctsWonWard()
    begin
    select case
		when sum(finalBiden) > sum(finalTrump) then 'Biden'
		else 'Trump'
	end as "Winner Of Ward", 
    sum(finalBiden) as "Total Biden Votes", sum(finalTrump) as "Total Trump Votes",  
    case
		when sum(finalBiden) > sum(finalTrump) then sum(finalBiden) - sum(finalTrump)
		else sum(finalTrump) - sum(finalBiden)
	end as "Difference in Votes"
	from
	(
		select precinct, max(Biden) as finalBiden, max(Trump) as finalTrump
		from Penna
		where precinct like "%Ward%"
		group by precinct
		order by precinct
	) a;
	end //
DELIMITER ; 

drop procedure if exists PrecinctsWonBorough;
DELIMITER //
create procedure PrecinctsWonBorough()
    begin
    select case
		when sum(finalBiden) > sum(finalTrump) then 'Biden'
		else 'Trump'
	end as "Winner Of Borough", 
    sum(finalBiden) as "Total Biden Votes", sum(finalTrump) as "Total Trump Votes",  
    case
		when sum(finalBiden) > sum(finalTrump) then sum(finalBiden) - sum(finalTrump)
		else sum(finalTrump) - sum(finalBiden)
	end as "Difference in Votes"
	from
	(
		select precinct, max(Biden) as finalBiden, max(Trump) as finalTrump
		from Penna
		where precinct like "% Borough%"
		group by precinct
		order by precinct
	) a;
	end //
DELIMITER ; 

drop procedure if exists PrecinctsWonDistrict;
DELIMITER //
create procedure PrecinctsWonDistrict()
    begin
    select case
		when sum(finalBiden) > sum(finalTrump) then 'Biden'
		else 'Trump'
	end as "Winner Of District", 
    sum(finalBiden) as "Total Biden Votes", sum(finalTrump) as "Total Trump Votes",  
    case
		when sum(finalBiden) > sum(finalTrump) then sum(finalBiden) - sum(finalTrump)
		else sum(finalTrump) - sum(finalBiden)
	end as "Difference in Votes"
	from
	(
		select precinct, max(Biden) as finalBiden, max(Trump) as finalTrump
		from Penna
		where precinct like "%District%"
		group by precinct
		order by precinct
	) a;
	end //
DELIMITER ; 

call PrecinctsWonTownship();
call PrecinctsWonWard();
call PrecinctsWonBorough();
call PrecinctsWonDistrict();

/*3a*/
drop procedure if exists TotalVotes;
DELIMITER //
create procedure TotalVotes(
	in inputTime timestamp, category varchar(255))
    begin
		if category like "ALL" then select precinct, totalvotes from penna where timestamp = inputTime order by totalvotes desc;
        elseif category like "Biden" then select precinct, biden from penna where timestamp = inputTime order by biden desc;
       elseif category like "Trump" then select precinct, trump from penna where timestamp = inputTime order by trump desc;
		else select "Not an option. Choose: ALL, Trump, or Biden" as Error;
        end if;
	end //
DELIMITER ; 

call TotalVotes("2020-11-11 21:50:46", "ALL");

/*3b*/
drop procedure if exists GainDelta;
DELIMITER //
create procedure GainDelta(
	in inputTime timestamp)
    begin
		select timestampdiff(second, a.timestamp, inputTime) as "Delta (seconds that passed)", (v.timeVotes - a.prevVotes) as "Gain",  
			((v.timeVotes - a.prevVotes) / timestampdiff(second, a.timestamp, inputTime)) as "Gain/Delta (votes per second)" from 
        (select sum(totalvotes) as timeVotes from penna where timestamp = inputTime group by timestamp) v, 
        (select distinct timestamp, sum(p.totalvotes) as prevVotes from penna p where timestamp < inputTime group by timestamp order by timestamp desc limit 1) a;
	end //
DELIMITER ; 

call GainDelta("2020-11-04 08:31:05");

/*3c*/
drop procedure if exists RankTimestamp;
DELIMITER //
create procedure RankTimestamp()
    begin
		drop table if exists timeTable;
		create temporary table timeTable(
		Timestamp timestamp
		) select distinct rank() over(order by timestamp) as id, timestamp from penna 
            group by timestamp order by timestamp desc;
        
		drop table if exists timeTable_two;
		create temporary table timeTable_two(
		Timestamp timestamp,
        votes int
		) select distinct rank() over(order by timestamp) as id, timestamp, sum(totalvotes) as votes from penna 
            group by timestamp order by timestamp desc;   
		
		drop table if exists gdTable;
		create temporary table gdTable(
		Timestamp timestamp,
        gd double
		) select v.timestamp, ((tt.votes - sum(v.totalvotes)) / timestampdiff(second, v.timestamp, tt.timestamp)) as gd from 
        penna v, timeTable t, timeTable_two tt where t.timestamp = v.timestamp and (t.id = tt.id+1)
			group by v.timestamp order by v.timestamp;
        
        select rank() over(order by gd desc) as "Rank", timestamp as "Timestamp", gd as "Gain/Delta (votes per second)" from gdTable;
    end //
DELIMITER ; 

call RankTimestamp();

/*3d*/
drop procedure if exists VotesPerDay;
DELIMITER //
create procedure VotesPerDay(
	in inputDay int)
    begin
		if inputDay >= 3 and inputDay <= 11 then 
		select (a.trump - b.trump) as Trump, (a.biden-b.biden) as Biden, (a.totalvotes-b.totalvotes) as TotalVotes from
			(select sum(trump) as trump, sum(biden) as biden, sum(totalvotes) as totalvotes from votes where timestamp = (select max(timestamp) from votes where dayofmonth(timestamp) = inputDay)) a,
			(select sum(trump) as trump, sum(biden) as biden, sum(totalvotes) as totalvotes from votes where timestamp = (select max(timestamp) from votes where dayofmonth(timestamp) = inputDay - 1)) b;
		else select "Not a valid input (enter day from 3 - 11)." as Error;
        end if;
	end //
DELIMITER ; 

call VotesPerDay("11");

/*4*/
select distinct p1.timestamp, p1.precinct, p1.trump, p1.biden, p1.totalvotes, p2.timestamp, p2.precinct, p2.trump, p2.biden, p2.totalvotes
				from penna p1, penna p2
                where p1.timestamp > p2.timestamp
					and p1.precinct = p2.precinct and (p1.trump < p2.trump or p1.biden < p2.biden or p1.totalvotes < p2.totalvotes);
                    
/*This query shows at which timestamp when a tuple has less votes than its previous timestamp. Here it shows many accounts where trump and biden lose and gain votes randomly.
This most likely means that the vote counters may have made a mistake while counting. This brings to question if these precincts made any more errors in its votes.
*/

