-- create schema 
create schema  mobile_project;
use mobile_project;



-- __________________________________________________________

delimiter //
create procedure dimensiontable()
begin

-- 1.Dim_Brand
      drop table if exists Dim_Brand;
      
      create table Dim_Brand(
          brand_id int auto_increment primary key,
          brand_name varchar(100) unique not null
          );
          
	  insert into Dim_Brand (brand_name)
      select distinct brand_name
      from smartphones;
      

      
-- 2.Dim_Model
      drop table if exists Dim_Model;
      
      create table Dim_Model(
          model_id int auto_increment primary key,
          model_name varchar(100),
          brand_id int
          );
          
	  insert into Dim_Model(model_name,brand_id)
      select distinct s.model, b.brand_id
      from smartphones s
      join Dim_Brand b on s.brand_name = b.brand_name;
      
      
            
-- 3.Dim_Processor
      drop table if exists Dim_Processor;
      
      create table Dim_Processor(
          processor_id int auto_increment primary key,
          processor_brand varchar(100),
          num_cores int,
          processor_speed double
          );
          
	  insert into Dim_Processor(processor_brand, num_cores,processor_speed)
      select distinct processor_brand,num_cores,processor_speed
      from smartphones;
      
      

-- 4.Dim_Battery
      drop table if exists Dim_Battery;
      
      create table Dim_Battery(
          battery_id int auto_increment primary key,
          battery_capacity int,
          fast_charging_available int,
          fast_charging int
          );
          
	  insert into Dim_Battery (battery_capacity,fast_charging_available,fast_charging)
      select distinct battery_capacity,fast_charging_available,fast_charging
      from smartphones;
      
            
-- 5.Dim_Memory
      Drop table if exists Dim_Memory;
      
      create table Dim_Memory(
      memory_id int auto_increment primary key,
      ram_capacity int,
      extended_memory_available int,
      internal_memory int
      );
      
      insert into Dim_Memory(ram_capacity,internal_memory,extended_memory_available)
      select distinct ram_capacity,internal_memory,extended_memory_available
      from smartphones;
      
	
      
-- 6.Dim_Display
Drop table if exists Dim_Display;

create table Dim_Display(
display_id int auto_increment primary key, 
screen_size double, 
refresh_rate int,
resolution_height int, 
resolution_width int 
);

insert into Dim_Display(screen_size,refresh_rate,resolution_height,resolution_width )
      select distinct screen_size,refresh_rate,resolution_height,resolution_width
      from smartphones;
      
      
      
      
-- 7.Dim_Camera
Drop table if exists Dim_Camera;

create table Dim_Camera(
camera_id int auto_increment primary key, 
num_rear_cameras int, 
primary_camera_rear int,
primary_camera_front int
);

insert into Dim_Camera(num_rear_cameras,primary_camera_rear,primary_camera_front )
      select distinct num_rear_cameras,primary_camera_rear,primary_camera_front
      from smartphones;
      
      
      
      
-- 8.Dim_OS
Drop table if exists Dim_OS;

create table Dim_OS(
os_id int auto_increment primary key, 
os varchar(100) unique not null
);

insert into Dim_OS(os)
      select distinct os
      from smartphones;
      
      
end //

delimiter ;      

call dimensiontable();




-- ____________________________________________________________________________-



-- fact table
delimiter //
create procedure Facttable()
begin

    drop table if exists fact_smartphones;
    
    create table fact_smartphones(
         smartphone_id int auto_increment primary key,
         brand_id int,
         model_id int,
         processor_id int,
         battery_id int,
         memory_id int,
         display_id int,
         camera_id int,
         os_id int,
         price int,
         avg_rating double,
		 is_5G int,
         
         
		FOREIGN KEY (brand_id) REFERENCES Dim_Brand(brand_id),
        FOREIGN KEY (model_id) REFERENCES Dim_Model(model_id),
        FOREIGN KEY (processor_id) REFERENCES Dim_Processor(processor_id),
        FOREIGN KEY (battery_id) REFERENCES Dim_Battery(battery_id),
        FOREIGN KEY (memory_id) REFERENCES Dim_Memory(memory_id),
        FOREIGN KEY (display_id) REFERENCES Dim_Display(display_id),
        FOREIGN KEY (camera_id) REFERENCES Dim_Camera(camera_id),
        FOREIGN KEY (os_id) REFERENCES Dim_OS(os_id)
         );
         
         insert into fact_smartphones(
         brand_id,model_id,processor_id,battery_id,memory_id,display_id,camera_id,os_id,price,avg_rating,is_5G
         )
         with filterdata as(
        select *,
               row_number() over(
               partition by brand_name, model, price, avg_rating, 5G_or_not, processor_brand,num_cores, processor_speed, battery_capacity, fast_charging_available,fast_charging, ram_capacity, internal_memory, screen_size,refresh_rate, num_rear_cameras, os, primary_camera_rear,primary_camera_front, extended_memory_available,resolution_height, resolution_width
					order by price
				) as rn
		from smartphones
        )
        select
        b.brand_id,
		m.model_id,
		p.processor_id,
		bat.battery_id,
		mem.memory_id,
		d.display_id,
		c.camera_id,
		o.os_id,
    
		s.price,
		s.avg_rating,
		s.5G_or_not as is_5G
FROM
    filterdata s

JOIN
    Dim_Brand b ON s.brand_name = b.brand_name
JOIN
    Dim_Processor p ON s.processor_brand = p.processor_brand
                    AND s.num_cores = p.num_cores
                    AND s.processor_speed = p.processor_speed
JOIN
    Dim_Battery bat ON s.battery_capacity = bat.battery_capacity
                     AND s.fast_charging_available = bat.fast_charging_available
                     AND s.fast_charging = bat.fast_charging
JOIN
    Dim_Memory mem ON s.ram_capacity = mem.ram_capacity
                   AND s.internal_memory = mem.internal_memory
                   AND s.extended_memory_available = mem.extended_memory_available
JOIN
    Dim_Display d ON s.screen_size = d.screen_size
                  AND s.refresh_rate = d.refresh_rate
                  AND s.resolution_height = d.resolution_height
                  AND s.resolution_width = d.resolution_width
JOIN
    Dim_Camera c ON s.num_rear_cameras = c.num_rear_cameras
                 AND s.primary_camera_rear = c.primary_camera_rear
                 AND s.primary_camera_front = c.primary_camera_front
JOIN
    Dim_OS o ON s.os = o.os
JOIN
    Dim_Model m ON s.model = m.model_name
                 AND b.brand_id = m.brand_id;
WHERE
        s.rn = 1;  -- ei jaigatate keno jani na bar bar vul hocche, solve korte parchi na
        
         
end //

delimiter ;


call Facttable();





-- ___________________________________________________________________________



-- 1. Total Sales and Average Price by Brand
SELECT
    b.brand_name,
    COUNT(f.smartphone_id) AS Total_Models,
    AVG(f.price) AS Average_Price
FROM Fact_Smartphones f
JOIN Dim_Brand b ON f.brand_id = b.brand_id
GROUP BY b.brand_name
ORDER BY Total_Models DESC;


-- 2. Top 5 Smartphones by Rating and Price
SELECT
    m.model_name,
    b.brand_name,
    f.avg_rating,
    f.price
FROM Fact_Smartphones f
JOIN Dim_Model m ON f.model_id = m.model_id
JOIN Dim_Brand b ON f.brand_id = b.brand_id
ORDER BY f.avg_rating DESC, f.price DESC
LIMIT 5;


-- 3. Smartphone Price Distribution by Brand and OS
SELECT
    b.brand_name,
    o.os,
    AVG(f.price) AS average_price
FROM Fact_Smartphones f
JOIN Dim_Brand b ON f.brand_id = b.brand_id
JOIN Dim_OS o ON f.os_id = o.os_id
GROUP BY b.brand_name, o.os
ORDER BY b.brand_name, o.os;


-- 4. Market Share by Brand and Processor Speed
SELECT
    b.brand_name,
    CASE
        WHEN p.processor_speed < 2.0 THEN '< 2.0 GHz'
        WHEN p.processor_speed >= 2.0 AND p.processor_speed < 2.5 THEN '2.0-2.5 GHz'
        ELSE '> 2.5 GHz'
    END AS processor_speed_bin,
    COUNT(f.smartphone_id) AS model_count
FROM Fact_Smartphones f
JOIN Dim_Brand b ON f.brand_id = b.brand_id
JOIN Dim_Processor p ON f.processor_id = p.processor_id
GROUP BY b.brand_name, processor_speed_bin
ORDER BY b.brand_name, model_count DESC;


-- 5. Number of Models and Avg Price by RAM Size and Brand
SELECT
    mem.ram_capacity,
    b.brand_name,
    COUNT(f.smartphone_id) AS total_models,
    AVG(f.price) AS average_price
FROM Fact_Smartphones f
JOIN Dim_Memory mem ON f.memory_id = mem.memory_id
JOIN Dim_Brand b ON f.brand_id = b.brand_id
GROUP BY mem.ram_capacity, b.brand_name
ORDER BY mem.ram_capacity, total_models DESC;


-- 6. Top 3 Fastest Charging Smartphones by Price
SELECT
    m.model_name,
    b.brand_name,
    bat.fast_charging,
    f.price
FROM Fact_Smartphones f
JOIN Dim_Model m ON f.model_id = m.model_id
JOIN Dim_Brand b ON f.brand_id = b.brand_id
JOIN Dim_Battery bat ON f.battery_id = bat.battery_id
WHERE bat.fast_charging_available = 1
ORDER BY bat.fast_charging DESC
LIMIT 3;


-- 7. Brand Performance by 5G Availability
SELECT
    b.brand_name,
    f.is_5G,
    AVG(f.avg_rating) AS average_rating
FROM Fact_Smartphones f
JOIN Dim_Brand b ON f.brand_id = b.brand_id
GROUP BY b.brand_name, f.is_5G
ORDER BY b.brand_name, f.is_5G;


-- 8. Correlation Between Processor Speed and Price by Brand
SELECT
    b.brand_name,
    CORR(p.processor_speed, f.price) AS price_speed_correlation
FROM Fact_Smartphones f
JOIN Dim_Processor p ON f.processor_id = p.processor_id
JOIN Dim_Brand b ON f.brand_id = b.brand_id
GROUP BY b.brand_name
HAVING COUNT(f.smartphone_id) > 20
ORDER BY price_speed_correlation DESC;


-- 9. Price-to-Performance Ratio by Brand
SELECT
    b.brand_name,
    AVG(
        ( (f.avg_rating * 1.5) + (p.processor_speed * 5) + (mem.ram_capacity * 2) + (bat.battery_capacity / 100) ) / f.price
    ) AS avg_price_performance_ratio
FROM Fact_Smartphones f
JOIN Dim_Brand b ON f.brand_id = b.brand_id
JOIN Dim_Processor p ON f.processor_id = p.processor_id
JOIN Dim_Memory mem ON f.memory_id = mem.memory_id
JOIN Dim_Battery bat ON f.battery_id = bat.battery_id
GROUP BY b.brand_name
ORDER BY avg_price_performance_ratio DESC
LIMIT 10;


-- 10. Most Popular Display Features
SELECT refresh_rate, COUNT(*) AS feature_count
FROM Dim_Display
GROUP BY refresh_rate
ORDER BY feature_count DESC
LIMIT 1;

SELECT screen_size, COUNT(*) AS feature_count
FROM Dim_Display
GROUP BY screen_size
ORDER BY feature_count DESC
LIMIT 1;

SELECT CONCAT(resolution_height, 'x', resolution_width) AS resolution,
       COUNT(*) AS feature_count
FROM Dim_Display
GROUP BY resolution
ORDER BY feature_count DESC
LIMIT 1;


-- 11. Multi-Feature Ranking (Composite Score)
WITH AllFeatures AS (
    SELECT
        m.model_name,
        b.brand_name,
        f.price,
        f.avg_rating,
        p.processor_speed,
        mem.ram_capacity,
        bat.battery_capacity,
        c.primary_camera_rear,
        d.refresh_rate
    FROM Fact_Smartphones f
    JOIN Dim_Model m ON f.model_id = m.model_id
    JOIN Dim_Brand b ON f.brand_id = b.brand_id
    JOIN Dim_Processor p ON f.processor_id = p.processor_id
    JOIN Dim_Memory mem ON f.memory_id = mem.memory_id
    JOIN Dim_Battery bat ON f.battery_id = bat.battery_id
    JOIN Dim_Camera c ON f.camera_id = c.camera_id
    JOIN Dim_Display d ON f.display_id = d.display_id
),
NormalizedFeatures AS (
    SELECT
        model_name,
        brand_name,
        price,
        (avg_rating - MIN(avg_rating) OVER()) / (MAX(avg_rating) OVER() - MIN(avg_rating) OVER()) AS norm_rating,
        (processor_speed - MIN(processor_speed) OVER()) / (MAX(processor_speed) OVER() - MIN(processor_speed) OVER()) AS norm_speed,
        (ram_capacity - MIN(ram_capacity) OVER()) / (MAX(ram_capacity) OVER() - MIN(ram_capacity) OVER()) AS norm_ram,
        (battery_capacity - MIN(battery_capacity) OVER()) / (MAX(battery_capacity) OVER() - MIN(battery_capacity) OVER()) AS norm_battery,
        (primary_camera_rear - MIN(primary_camera_rear) OVER()) / (MAX(primary_camera_rear) OVER() - MIN(primary_camera_rear) OVER()) AS norm_camera,
        (refresh_rate - MIN(refresh_rate) OVER()) / (MAX(refresh_rate) OVER() - MIN(refresh_rate) OVER()) AS norm_refresh
    FROM AllFeatures
),
CompositeScore AS (
    SELECT
        model_name,
        brand_name,
        price,
        (norm_rating + norm_speed + norm_ram + norm_battery + norm_camera + norm_refresh) AS composite_score
    FROM NormalizedFeatures
)
SELECT
    model_name,
    brand_name,
    composite_score,
    price,
    (price / composite_score) AS value_score
FROM CompositeScore
ORDER BY composite_score DESC
LIMIT 5;


-- 12. Average Battery Capacity and Fast-Charging Comparison by OS
SELECT
    o.os,
    AVG(bat.battery_capacity) AS average_battery_capacity,
    (AVG(bat.fast_charging_available) * 100) AS fast_charging_support_pct
FROM Fact_Smartphones f
JOIN Dim_OS o ON f.os_id = o.os_id
JOIN Dim_Battery bat ON f.battery_id = bat.battery_id
GROUP BY o.os;