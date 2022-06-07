/*4.1*/

/*STORED PROCEDURES*/
/*UPDATING*/
drop procedure if exists new_update;
DELIMITER //
create procedure new_update(
	InD int,
	timest timestamp,
    stat varchar(255),
    local varchar(255),
    prect varchar(255),
    geog varchar(255),
    totvotes int,
    bid int,
    tru int, 
    tableName varchar(255)
)
    Upd: begin
		declare exit handler for 1452 select 'Update rejected due to foreign key violation' as 'Error1';
		declare exit handler for 1062 select 'Update rejected due to primary key violation' as 'Error2';
        if (bid + tru > totvotes) then select 'Update rejected due to contraint violation' as 'Error4';
			leave Upd;
        end if;
        if (timest < "2020-11-03" or timest > "2020-11-12") then select 'Update rejected due to contraint violation' as 'Error5';
			leave Upd;
        end if;

            
        if tableName like 'votes' then 
			if (select count(*) from (select *
				from votes p1
                where p1.timestamp > timest
					and p1.precinct = prect and (p1.trump < tru or p1.biden < bid or p1.totalvotes < totvotes))a ) > 0
                    then select 'Update rejected due to contraint violation' as 'Error3';
			leave Upd;
            end if;
            
			update votes set totalvotes = totvotes, biden = bid, trump = tru where timestamp = timest and precinct = prect;
            
        elseif tableName like 'precincts' then
			if (select count(*) from precincts where precinct = prect) > 0 then
				update precincts set ID = InD, precinct = prect, state = stat, locality = local, geo = geog where precinct = prect;
			end if;
            
        elseif tableName like 'penna' then
        
			if (select count(*) from (select *
				from penna p1
                where p1.timestamp > timest
					and p1.precinct = prect and (p1.trump < tru or p1.biden < bid or p1.totalvotes < totvotes))a ) > 0
                    then select 'Update rejected due to contraint violation' as 'Error3';
			leave Upd;
            end if;
            
			update penna set totalvotes = totvotes, biden = bid, trump = tru where ID = InD and state = stat and geo = geog and timestamp = timest and precinct = prect;

        else 
			select 'Not an existing table name' as 'Error8';
			leave Upd;
        end if;
        select 'Update Accepted' as 'Success';
    end //
DELIMITER ;

call new_update(1000, "2020-11-04 01:11:32", 'PA', 'L', 'BELLEFONTE SOUTH', 'geo', 314, 215, 93, 'votes');
/*INSERTION*/
drop procedure if exists new_insert;
DELIMITER //
create procedure new_insert(
	InD int,
	timest timestamp,
    stat varchar(255),
    local varchar(255),
    prect varchar(255),
    geog varchar(255),
    totvotes int,
    bid int,
    tru int, 
    tableName varchar(255)
)
    Ins: begin
		declare exit handler for 1452 select 'Insertion rejected due to foreign key violation' as 'Error1';
        declare exit handler for 1062 select 'Insertion rejected due to primary key violation' as 'Error6';
		if (bid + tru > totvotes) then select 'Insertion rejected due to contraint violation' as 'Error2';
			leave Ins;
        end if;
        if (timest < "2020-11-03" or timest > "2020-11-12") then select 'Insertion rejected due to contraint violation' as 'Error3';
			leave Ins;
        end if;
        if tableName like 'votes' then 
			if (select count(*) from (select *
				from votes p1
                where p1.timestamp > timest
					and p1.precinct = prect and (p1.trump < tru or p1.biden < bid or p1.totalvotes < totvotes))a ) > 0
                    then select 'Insertion rejected due to contraint violation' as 'Error4';
			leave Ins;
            end if;
            
			insert into votes(timestamp, precinct, totalvotes, biden, trump) value (timest, prect, totvotes, bid, tru);
        elseif tableName like 'precincts' then
			insert into precincts(ID, precinct, state, locality, geo) value (InD, prect, stat, local, geog);
        elseif tableName like 'penna' then
			if (select count(*) from (select *
			from penna p1
            where p1.timestamp > timest
				and p1.precinct = prect and (p1.trump < tru or p1.biden < bid or p1.totalvotes < totvotes))a ) > 0
                then select 'Insertion rejected due to contraint violation' as 'Error5';
			leave Ins;
            end if;
            
			insert into penna(ID, timestamp, state, locality, precinct, geo, totalvotes, biden, trump) value (InD, timest, stat, local, prect, geog, totvotes, bid, tru);
        else 
			select 'Not an existing table name' as 'Error';
            leave Ins;
        end if;
        select 'Insertion Accepted' as 'Success';
    end //
DELIMITER ;

call new_insert(1000, "2020-11-04 02:33:10", 'PA', 'L', 'Abington 1-1', 'geo', 100, 100, 0, 'votes');

/*DELETION*/
drop procedure if exists new_delete;
DELIMITER //
create procedure new_delete(
	InD int,
	timest timestamp,
    stat varchar(255),
    local varchar(255),
    prect varchar(255),
    geog varchar(255),
    totvotes int,
    bid int,
    tru int, 
    tableName varchar(255)
)
    Del: begin
		declare exit handler for 1451 select 'Deletion rejected due to foreign key violation' as 'Error1';
    
        if tableName like 'votes' then 
			delete from votes where timestamp = timest and precinct = prect and totalvotes = totvotes and biden = bid and trump = tru;
        elseif tableName like 'precincts' then
			delete from precincts where ID = InD and precinct = prect and state = stat and locality = local and geo = geog;
        elseif tableName like 'penna' then
			delete from penna where ID = InD and timestamp = timest and state = stat and locality = local and precinct = prect 
				and geo = geog and totalvotes = totvotes and biden = bid and trump = tru;
        else 
			select 'Not an existing table name' as 'Error';
			leave Del;
        end if;
        select 'Deletion Accepted' as 'Success';
    end //
DELIMITER ;

call new_delete(1000, "2020-09-10", 'PA', 'L', 'Abington 1-1', 'geo', 100, 50, 50, 'votes');

/*TRIGGERS*/
/*UPDATES*/
create table if not exists Updated_Votes_Tuples like votes;
drop trigger if exists UpdVotesTrig;
delimiter //
create trigger UpdVotesTrig
before update on votes for each row
begin
	insert into Updated_Votes_Tuples values (old.timestamp, old.precinct, old.totalvotes, old.biden, old.trump);
end //
delimiter ;

create table if not exists Updated_Precinct_Tuples like precincts;
drop trigger if exists UpdPrecTrig;
delimiter //
create trigger UpdPrecTrig
before update on precincts for each row
begin
	insert into Updated_Precinct_Tuples values (old.ID, old.precinct, old.state, old.locality, old.geo);
end //
delimiter ;

create table if not exists Updated_Penna_Tuples like penna;
drop trigger if exists UpdPennaTrig;
delimiter //
create trigger UpdPennaTrig
before update on penna for each row
begin
	insert into Updated_Penna_Tuples values (old.ID, old.Timestamp, old.state, old.locality, old.precinct, old.geo, old.totalvotes, old.biden, old.trump, old.filestamp);
end //
delimiter ;

/*INSERTS*/
create table if not exists Inserted_Votes_Tuples like votes;
drop trigger if exists InsVotesTrig;
delimiter //
create trigger InsVotesTrig
before insert on votes for each row
begin
	insert into Inserted_Votes_Tuples values (new.timestamp, new.precinct, new.totalvotes, new.biden, new.trump);
end //
delimiter ;

create table if not exists Inserted_Precinct_Tuples like precincts;
drop trigger if exists InsPrecTrig;
delimiter //
create trigger InsPrecTrig
before insert on precincts for each row
begin
	insert into Inserted_Precinct_Tuples values (new.ID, new.precinct, new.state, new.locality, new.geo);
end //
delimiter ;

create table if not exists Inserted_Penna_Tuples like penna;
drop trigger if exists InsPennaTrig;
delimiter //
create trigger InsPennaTrig
before insert on penna for each row
begin
	insert into Inserted_Penna_Tuples values (new.ID, new.Timestamp, new.state, new.locality, new.precinct, new.geo, new.totalvotes, new.biden, new.trump, new.filestamp);
end //
delimiter ;


/*DELETES*/
create table if not exists Deleted_Votes_Tuples like votes;
drop trigger if exists DelVotesTrig;
delimiter //
create trigger DelVotesTrig
before delete on votes for each row
begin
	insert into Deleted_Votes_Tuples values (old.timestamp, old.precinct, old.totalvotes, old.biden, old.trump);
end //
delimiter ;

create table if not exists Deleted_Precinct_Tuples like precincts;
drop trigger if exists DelPrecTrig;
delimiter //
create trigger DelPrecTrig
before delete on precincts for each row
begin
	insert into Deleted_Precinct_Tuples values (old.ID, old.precinct, old.state, old.locality, old.geo);
end //
delimiter ;

create table if not exists Deleted_Penna_Tuples like penna;
drop trigger if exists DelPennaTrig;
delimiter //
create trigger DelPennaTrig
before delete on penna for each row
begin
	insert into Deleted_Penna_Tuples values (old.ID, old.Timestamp, old.state, old.locality, old.precinct, old.geo, old.totalvotes, old.biden, old.trump, old.filestamp);
end //
delimiter ;

/*4.2*/
drop procedure if exists MoreVotes;
DELIMITER //
create procedure MoreVotes(
	Prec varchar(255),
    Timest timestamp,
    CoreCandidate varchar(255),
    Number_of_Moved_Votes int
    )
    MV: begin
		if (select count(*) from (select precinct from penna where precinct = Prec) a) < 1 then select 'Uknown Precinct' as 'value';
			leave MV;
		end if;
        if (select count(*) from (select distinct timestamp from penna where timestamp = Timest) a) < 1 then select 'Uknown Timestamp' as 'value';
			leave MV;
		end if;
        if CoreCandidate not like 'trump' and CoreCandidate not like 'biden' then select 'Wrong Candidate' as 'value';
			leave MV;
		end if;
        if Number_of_Moved_Votes < 1 then select 'Number must be greater than 0' as 'value';
			leave MV;
		end if;
        
        if CoreCandidate like 'trump' then 
			if (select distinct trump from penna where timestamp = Timest and precinct = Prec) < Number_of_Moved_Votes then select 'Not enough votes' as 'value';
            leave MV;
            end if;
            update penna set trump = trump - Number_of_Moved_Votes, biden = biden + Number_of_Moved_Votes where precinct = Prec and timestamp >= Timest;
		elseif CoreCandidate like 'biden' then 
			if (select distinct biden from penna where timestamp = Timest and precinct = Prec) < Number_of_Moved_Votes then select 'Not enough votes' as 'value';
            leave MV;
            end if;
            update penna set trump = trump + Number_of_Moved_Votes, biden = biden - Number_of_Moved_Votes where precinct = Prec and timestamp >= Timest;
		end if;
        
    end//
DELIMITER ;
