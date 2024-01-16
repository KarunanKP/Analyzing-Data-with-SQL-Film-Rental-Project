-- ---------------------------------------------------------------------------------------------------------------------
--                                               Film - Rental
-- ---------------------------------------------------------------------------------------------------------------------

select * from Actor;
select * from Address; 
select * from category; 
select * from city; 
select * from country; 
select * from customer; 
select * from film; 
select * from film_actor; 
select * from film_category;
select * from inventory;   
select * from language;  
select * from payment;  
select * from rental; 
select * from staff;  
select * from store;  


-- 1. What is the total revenue generated from all rentals in the database?

select sum(amount) as Total_Revenue
from payment;

-- ---------------------------------------------------------------------------------------------------------------------
-- 2. How many rentals were made in each month_name?

select monthname(rental_date) as month_name , count(rental_date) as rental_each_month
from rental 
group by month_name;

-- ---------------------------------------------------------------------------------------------------------------------
-- 3. What is the rental rate of the film with the longest title in the database?   

select title, rental_rate
from film
where length(title) = (select max(length(title)) from film);

-- ---------------------------------------------------------------------------------------------------------------------
-- 4. What is the average rental rate for films that were taken from the last 30 days from the date("2005-05-05 22:04:30")?

select avg(rental_rate) as average_rental_rate
from rental join inventory using(inventory_id) join film using(film_id)
where rental_date in (with cte2 as( with cte1 as ( select distinct date(rental_date) as date_distinct
												   from rental where rental_date > '2005-05-05' )
								    select *, row_number() over(order by date_distinct desc) as day_count from cte1 )
					  select date_distinct from cte2 where day_count <= 30 );

-- ---------------------------------------------------------------------------------------------------------------------
-- 5. What is the most popular category of films in terms of the number of rentals?

select category , rental_numbers
from ( select c.name as category, count(rental_id) as rental_numbers,dense_rank() over(order by count(rental_id) desc) as ranking
       from category c join film_category fc using (category_id)
                       join film f using (film_id)
                       join inventory i using (film_id)
                       join rental r using (inventory_id)
       group by c.name) as sub
where sub.ranking = 1;

-- ---------------------------------------------------------------------------------------------------------------------
-- 6. Find the longest movie duration from the list of films that have not been rented by any customer.

select film_id, title, length_of_movie, rental_status
from ( select f.film_id, f.title, f.length as length_of_movie, r.inventory_id as rental_status, dense_rank() over(order by f.length desc) as ranking
	   from film f left join inventory i using (film_id)
			       left join rental r using (inventory_id)
	   where r.inventory_id is null) as sub
 where sub.ranking = 1;
 
-- ---------------------------------------------------------------------------------------------------------------------
-- 7. What is the average rental rate for films, broken down by category?

select c.name as category, avg(rental_rate) as average_rental_rate
from category c join film_category fc using(category_id)
                join film f using(film_id)
group by category;

-- ---------------------------------------------------------------------------------------------------------------------
-- 8. What is the total revenue generated from rentals for each actor in the database?

select a.actor_id, concat(a.first_name, ' ', a.last_name) as actor_name, sum(p.amount) as total_revenue
from actor a join film_actor fa using (actor_id)
			 join film f using (film_id)
             join inventory i using (film_id) 
             join rental r using (inventory_id) 
             join payment p using (rental_id)
group by a.actor_id, a.first_name, a.last_name;

-- ---------------------------------------------------------------------------------------------------------------------
-- 9. Show all the actresses who worked in a film having a "Wrestler" in the description.

select a.actor_id, concat(a.first_name, ' ', a.last_name) as actor_name
from film f join film_actor fa using (film_id)
            join actor a using (actor_id)
where description like '%wrestler%'
group by a.actor_id;

-- ---------------------------------------------------------------------------------------------------------------------
-- 10. Which customers have rented the same film more than once?

select c.customer_id, concat(c.first_name, ' ', c.last_name) as customer_name , f.film_id, count(*) as rental_count
from film f join inventory i using (film_id)
			join rental r using (inventory_id)
            join customer c using (customer_id)
group by c.customer_id, customer_name, f.film_id
having count(*) > 1;

-- ---------------------------------------------------------------------------------------------------------------------
-- 11. How many films in the comedy category have a rental rate higher than the average rental rate?

select c.name, count(f.film_id) as rental_count
from category c join film_category fc using(category_id)
                join film f using(film_id)
where c.name = 'Comedy' and rental_rate > (select avg(rental_rate) from film);  

-- ---------------------------------------------------------------------------------------------------------------------
-- 12. Which films have been rented the most by customers living in each city?

select city_id, city, title, rental_count
from (select ci.city_id, ci.city, f.title, count(rental_id) as rental_count, dense_rank() over(partition by ci.city_id order by count(rental_id) desc) as ranking
			  from city ci join address a using (city_id)
						   join customer c using (address_id)
						   join rental r using (customer_id)
						   join inventory i using (inventory_id)
						   join film f using (film_id)
			  group by ci.city_id, ci.city, f.title) as sub
where ranking = 1;

-- ---------------------------------------------------------------------------------------------------------------------
-- 13. What is the total amount spent by customers whose rental payments exceed $200?

select c.customer_id, sum(amount) as rental_payment 
from customer c join payment p using (customer_id)
group by c.customer_id
having rental_payment > '200';

-- ---------------------------------------------------------------------------------------------------------------------
-- 14. Display the fields which are having foreign key constraints related to the "rental" table.
-- [Hint: using Information_schema]

select * from information_schema.table_constraints
where table_name = 'rental' and table_schema = 'film_rental'
                            and constraint_type = 'FOREIGN KEY';
                            
-- ---------------------------------------------------------------------------------------------------------------------                            
-- 15. Create a View for the total revenue generated by each staff member, broken down by store city with the country name.  

create view staff_total_revenue as 
select s.staff_id, concat(s.first_name, ' ', s.last_name) as staff_name, c.city, cy.country, sum(p.amount) as total_revenue
from staff s join store st using (store_id)
			 join address ad on st.address_id = ad.address_id
             join city c using (city_id)
             join country cy using (country_id)
             join payment p using (staff_id)
group by s.staff_id, s.first_name, s.last_name, c.city, cy.country;

select * from staff_total_revenue;

-- ---------------------------------------------------------------------------------------------------------------------                            
-- 16. Create a view based on rental information consisting of visiting_day, customer_name, the title of the film,
-- no_of_rental_days, the amount paid by the customer along with the percentage of customer spending.

create view rental_information as
select c.customer_id, rental_date, concat(c.first_name, ' ', c.last_name) as customer_name, title, rental_duration, amount as paid_amount,
((amount/ (select sum(amount) from payment)) *100) as pct
from rental join inventory using (inventory_id)
            join film using (film_id)
            join customer c using (customer_id)
            join payment using (rental_id)
group by c.customer_id, rental_date, title, rental_duration, paid_amount;

select * from rental_information;

-- ---------------------------------------------------------------------------------------------------------------------                            
-- 17. Display the customers who paid 50% of their total rental costs within one day.

select c.customer_id,f.film_id, (f.rental_rate * f.rental_duration) as rental_cost , p.amount, (p.amount/(f.rental_rate * f.rental_duration))*100 as pct_paid
from film f join inventory i using (film_id)
			join rental r using (inventory_id)
            join customer c using (customer_id)
            join payment p using (rental_id)
where (p.amount/(f.rental_rate * f.rental_duration)) > 0.5 and payment_date < date_add(r.rental_date, interval 1 day);
