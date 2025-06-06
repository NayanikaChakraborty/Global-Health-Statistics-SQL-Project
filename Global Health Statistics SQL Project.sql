create table global_health_statistics as (
	select * from global_health_statistics_2018
	union all
	select * from global_health_statistics_2019
    union all
	select * from global_health_statistics_2020
	union all
	select * from global_health_statistics_2021
	union all
	select * from global_health_statistics_2022
    union all
	select * from global_health_statistics_2023
	union all
	select * from global_health_statistics_2024
);

select *
from global_health_statistics;


-- Question 1. which top 3 diseases have affected the highest number of people? --

select DiseaseName, sum(PopulationAffected) as total_affected_people
from global_health_statistics
group by DiseaseName
order by total_affected_people desc
limit 3;

-- Question 2. In which year the total number of affected people is highest? --

select Year, sum(PopulationAffected) as total_affected_people
from global_health_statistics
group by Year
order by total_affected_people desc
limit 1;

-- Question 3. Find the most affected age group in case of each disease. --

alter table global_health_statistics
add column Age_Group varchar(50)
after agegroup;

update global_health_statistics
set Age_Group = case
		    when AgeGroup = "0-18" then "Children"
                    when AgeGroup = "19-35" then "Adult"
                    when AgeGroup = "36-60" then "Middle-age"
                    else "Old-age"
				end;
            

select DiseaseName, Age_Group as Most_affected_age_group, sum(PopulationAffected) as total_affected_people
from global_health_statistics g
group by DiseaseName, Age_Group
having sum(PopulationAffected) = (select max(total_affected_people)
				  from (select DiseaseName, Age_Group, sum(PopulationAffected) 
					as total_affected_people
					from global_health_statistics
					group by DiseaseName, Age_Group) sub
				  where g.DiseaseName = sub.DiseaseName);

-- Question 4. Identify Most common disease in each demographic group. --

alter table global_health_statistics
add column Demographic_group varchar(50)
after gender;

update global_health_statistics
set Demographic_group = concat(Age_Group,"-",Gender);

with affected_demographic_group as (
select Demographic_group, DiseaseName, sum(PopulationAffected) as total_affected_people
from global_health_statistics
group by Demographic_group, DiseaseName
)
select Demographic_group, DiseaseName
from affected_demographic_group a1
where total_affected_people = (select max(total_affected_people)
			       from affected_demographic_group a2
                               where a1.Demographic_group = a2.Demographic_group)
order by Demographic_group;

-- Question 5. Find the top 5 countries with the highest and the lowest number of affected people? --

select ï»¿Country as country_with_the_highest_number_of_affected_people, sum(PopulationAffected) as
total_affected_people
from global_health_statistics
group by ï»¿Country
order by total_affected_people desc
limit 5;

select ï»¿Country as country_with_the_lowest_number_of_affected_people, sum(PopulationAffected) as 
total_affected_people
from global_health_statistics
group by ï»¿Country
order by total_affected_people
limit 5;


/* Question 6. Find the percentage change in new cases over the years in case of each disease.
Also find the country with the highest positive change in new cases in case of each disease. */

with new_cases as (
select Year, DiseaseName, round(sum(PopulationAffected * IncidenceRate/100),0) as number_of_new_cases,
round(lag(sum(PopulationAffected * IncidenceRate/100)) over (partition by DiseaseName order by Year),0) as 
Previous_year_number_of_new_cases
from global_health_statistics
group by Year, DiseaseName
)
select Year, DiseaseName, number_of_new_cases, Previous_year_number_of_new_cases,
round(((number_of_new_cases - Previous_year_number_of_new_cases)/Previous_year_number_of_new_cases)*100,2)
as Percentage_change_in_new_cases
from new_cases
where Previous_year_number_of_new_cases is not null;


with new_cases as (
select Year, DiseaseName, ï»¿Country, round(sum(PopulationAffected * IncidenceRate/100),0) as 
number_of_new_cases,
round(lag(sum(PopulationAffected * IncidenceRate/100)) over 
(partition by DiseaseName, ï»¿Country order by Year),0) as Previous_year_number_of_new_cases
from global_health_statistics
group by Year, DiseaseName, ï»¿Country
),
Percentage_change as (
select Year, DiseaseName, ï»¿Country, number_of_new_cases, Previous_year_number_of_new_cases,
round(((number_of_new_cases - Previous_year_number_of_new_cases)/Previous_year_number_of_new_cases)*100,2)
as Percentage_change_in_new_cases
from new_cases
where Previous_year_number_of_new_cases is not null
)
select DiseaseName, Year as Year_with_max_new_cases, ï»¿Country as Country_with_max_new_cases,
Percentage_change_in_new_cases
from Percentage_change p1
where Percentage_change_in_new_cases = (select max(Percentage_change_in_new_cases)
					from Percentage_change p2
					where p1.DiseaseName = p2.DiseaseName);

/* Question 7. Find disease categories with the highest percentage of recovered people 
in case of each disease. */

with recovered_people as(
select DiseaseName, DiseaseCategory, round((sum(PopulationAffected * RecoveryRate/100)/
sum(PopulationAffected))*100,2) as Percentage_of_recovered_people
from global_health_statistics
group by DiseaseName, DiseaseCategory
)
select distinct DiseaseName,
first_value(DiseaseCategory) over (partition by DiseaseName order by Percentage_of_recovered_people desc) as
Disease_Category_with_max_recovered_people
from recovered_people;

-- Question 8. Find the countries with the highest number of recovered people in case of each disease. --

select DiseaseName, ï»¿Country as Country_with_highest_recovered_people, 
round(sum(PopulationAffected * RecoveryRate/100),0) as number_of_recovered_people
from global_health_statistics g
group by DiseaseName, ï»¿Country
having round(sum(PopulationAffected * RecoveryRate/100),0) =
						(select max(number_of_recovered_people)
						from (select DiseaseName, ï»¿Country, 
						      round(sum(PopulationAffected * RecoveryRate/100),0) 
                                                      as number_of_recovered_people
						      from global_health_statistics
						      group by DiseaseName, ï»¿Country) sub
						where g.DiseaseName = sub.DiseaseName);

-- Question 9. Which disease caused the highest number of deaths? --

select DiseaseName, round(sum(PopulationAffected * MortalityRate/100),0) as number_of_deaths
from global_health_statistics
group by DiseaseName
order by number_of_deaths desc
limit 1;

/* Question 10. Find the percentage change in the number of deaths over the years 
in case of each disease. */ 

with yearly_deaths as (
select Year, DiseaseName, round(sum(PopulationAffected * MortalityRate/100),0) as number_of_deaths,
round(lag(sum(PopulationAffected * MortalityRate/100)) over (partition by DiseaseName order by year),0) 
as Previous_year_number_of_deaths
from global_health_statistics
group by Year, DiseaseName
)
select Year, DiseaseName, number_of_deaths, Previous_year_number_of_deaths,
round(((number_of_deaths - Previous_year_number_of_deaths)/Previous_year_number_of_deaths)*100,2) 
as Percentage_change
from yearly_deaths
where Previous_year_number_of_deaths is not null;

-- Question 11. Find the disease category that caused the highest number of deaths in case of each disease. --

with deaths_in_diseasecategory as (
select DiseaseName, DiseaseCategory, round(sum(PopulationAffected * MortalityRate/100),0) as number_of_deaths
from global_health_statistics
group by DiseaseName, DiseaseCategory
)
select DiseaseName, DiseaseCategory, number_of_deaths
from deaths_in_diseasecategory d1
where number_of_deaths = (select max( number_of_deaths)
			  from deaths_in_diseasecategory d2
                          where d1.DiseaseName = d2.DiseaseName);


-- Question 12. Find the most harmful disease category.--

select  DiseaseCategory, round(sum(PopulationAffected * MortalityRate/100),0) as number_of_deaths
from global_health_statistics
group by DiseaseCategory
order by number_of_deaths desc
limit 1;

/* Question 13. Write a Procedure to find the disease that caused the highest number of deaths globally
 in a particular year. Using it find the disease that caused highest number of deaths in 2022*/

Delimiter //
create procedure Disease_caused_highest_deaths (in Year1 int)
	select DiseaseName
	from global_health_statistics
        where year = Year1
	group by year, DiseaseName
	order by sum(PopulationAffected*MortalityRate/100) desc
	limit 1;
end //
Delimiter ;

call Disease_caused_highest_deaths ("2022");

/* Question 14. Find the top 5 diseases with the highest DALYs (combining years of life lost due to 
premature death and years of life lived with a disability). */

select DiseaseName, avg(DALYs) as Global_Burden_of_Disease
from global_health_statistics
group by DiseaseName
order by Global_Burden_of_Disease desc
limit 5;

/* Also find the countries with the highest DALYs (combining years of life lost due to 
premature death and years of life lived with a disability) in case of each disease. */

with Disease_Burden as (
select DiseaseName, ï»¿Country, avg(DALYs) as Burden_of_Disease
from global_health_statistics
group by DiseaseName, ï»¿Country
)
select distinct DiseaseName,
first_value(ï»¿Country) over (partition by DiseaseName order by Burden_of_Disease desc)
as Country_with_highest_Burden_of_Disease
from Disease_Burden;

-- Question 15. In case of each disease which treatment type is most effective? -- 

with treatment_type as (                           
select DiseaseName, TreatmentType, round(sum(PopulationAffected * RecoveryRate/100),0) as recovered_people
from global_health_statistics
group by DiseaseName, TreatmentType
)
select distinct DiseaseName, last_value(TreatmentType) over (partition by DiseaseName order by recovered_people
rows between unbounded preceding and unbounded following) as Most_beneficial_treatment_type
from treatment_type;
                        
-- Question 16. Find the countries with the highest treatment cost for each treatment type of each disease. --

with treatment_cost as (
select DiseaseName, TreatmentType, ï»¿Country, avg(AverageTreatmentCost) as avg_treatment_cost
from global_health_statistics
group by DiseaseName, TreatmentType, ï»¿Country
)
select DiseaseName, TreatmentType, ï»¿Country as Country_with_highest_treatment_cost
from treatment_cost tc1
where avg_treatment_cost = (select max(avg_treatment_cost)
			    from treatment_cost tc2
			    where tc1.DiseaseName = tc2.DiseaseName
                            and tc1.TreatmentType = tc2.TreatmentType)
order by DiseaseName;
				
--  Find the countries with the lowest treatment cost for each treatment type of each disease. --

with treatment_cost as (
select DiseaseName, TreatmentType, ï»¿Country, avg(AverageTreatmentCost) as avg_treatment_cost
from global_health_statistics
group by ï»¿Country, DiseaseName, TreatmentType
)
select DiseaseName, TreatmentType, ï»¿Country as Country_with_lowest_treatment_cost
from treatment_cost tc1
where avg_treatment_cost = (select min(avg_treatment_cost)
			    from treatment_cost tc2
			    where tc1.DiseaseName = tc2.DiseaseName
                            and tc1.TreatmentType = tc2.TreatmentType)
order by DiseaseName;

-- Question 17. Find the three countries with the lowest number of affected people having healthcare access. --

select ï»¿Country as Country_with_min_healthcare_access
from global_health_statistics
group by ï»¿Country
order by round(sum(PopulationAffected * HealthcareAccess/100),0)
limit 3;

-- Question 18. Find the countries where demand of vaccines or treatment is high in case of each disease. --

with vaccines_or_treatment_availability as (
select DiseaseName, ï»¿Country, Availability_of_Vaccines_or_Treatment, sum(PopulationAffected) 
as number_of_affected_people
from global_health_statistics
group by DiseaseName, ï»¿Country, Availability_of_Vaccines_or_Treatment
)
select DiseaseName, ï»¿Country as Country_with_high_demand_of_vaccines_or_treatment
from vaccines_or_treatment_availability vt1
where Availability_of_Vaccines_or_Treatment = "No"
and number_of_affected_people = (select max(number_of_affected_people)
				 from vaccines_or_treatment_availability vt2
				 where vt1.DiseaseName = vt2.DiseaseName);

-- Question 19. Which countries have maximum and minimum average number of doctors in case of each disease? --

select distinct DiseaseName, last_value(ï»¿Country) over (partition by DiseaseName order by number_of_doctors
rows between unbounded preceding and unbounded following) as Country_with_max_number_of_doctors_per_1000,
first_value(ï»¿Country) over (partition by DiseaseName order by number_of_doctors)
as Country_with_min_number_of_doctors_per_1000
from (
	select DiseaseName, ï»¿Country, avg(Doctors_per_1000) as number_of_doctors
	from global_health_statistics
	group by DiseaseName, ï»¿Country) sub;                                

-- Question 20. Which countries have maximum and minimum average number of hospital beds in case of each disease? --
                                 
select distinct DiseaseName, last_value(ï»¿Country) over (partition by DiseaseName order by number_of_hospital_beds
rows between unbounded preceding and unbounded following) as Country_with_max_number_of_beds_per_1000,
first_value(ï»¿Country) over (partition by DiseaseName order by number_of_hospital_beds)
as Country_with_min_number_of_beds_per_1000
from (
      select DiseaseName, ï»¿Country, avg(Hospital_Beds_per_1000) as number_of_hospital_beds
      from global_health_statistics
      group by DiseaseName, ï»¿Country) sub;

