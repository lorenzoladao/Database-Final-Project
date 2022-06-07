/*a*/
select "FALSE" as "Votes Normal?"
from penna p
where exists (select p1.totalvotes 
				from penna p1, penna p2 
                where p1.totalvotes < p1.trump + p2.biden and p1.Timestamp = p2.Timestamp and p1.precinct = p2.precinct)
union
select "TRUE" as "Votes Normal?"
from penna p
where exists (select p1.totalvotes 
				from penna p1, penna p2 
                where p1.totalvotes > p1.trump + p2.biden and p1.Timestamp = p2.Timestamp and p1.precinct = p2.precinct);
                
/*b*/
select "FALSE" as "Timestamps Valid?"
from penna p
where exists (select distinct timestamp 
				from penna
                where timestamp < "2020-11-03" or timestamp > "2020-11-12")
union
select "TRUE" as "Timestamps Valid?"
from penna p
where not exists (select distinct timestamp 
				from penna
                where timestamp < "2020-11-03" or timestamp > "2020-11-12");
                
/*c*/
select "FALSE" as "Valid Votes after 2020-11-05?"
from penna p
where exists (select p1.timestamp, p1.precinct, p1.trump, p1.biden, p1.totalvotes
				from penna p1, penna p2
                where p1.timestamp > "2020-11-05 00:00:00" and p2.timestamp = (select max(timestamp) from penna where timestamp <= "2020-11-05 00:00:00")
					and p1.precinct = p2.precinct and (p1.trump < p2.trump or p1.biden < p2.biden or p1.totalvotes < p2.totalvotes))
union
select "TRUE" as "Valid Votes after 2020-11-05?"
from penna p
where not exists (select p2.timestamp, p2.precinct, p2.trump, p2.biden, p2.totalvotes
				from penna p1, penna p2
                where p1.timestamp > "2020-11-05 00:00:00" and p2.timestamp = (select max(timestamp) from penna where timestamp <= "2020-11-05 00:00:00")
					and p1.precinct = p2.precinct and (p1.trump < p2.trump or p1.biden < p2.biden or p1.totalvotes < p2.totalvotes));
			