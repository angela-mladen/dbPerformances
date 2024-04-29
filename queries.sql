--Query 1:List the books with their prices, which title contains less than 5 words and the price is not zero.
-- Order the result in descending order
select distinct title, price
from books_ratings
where length(title) - length(replace(title,' ','')) + 1 < 5
and price != 0
order by price DESC;

--Query 2:List the titles of the books that have the best rating(5), the rating's text contains more than 5 words,
-- the summarization text has more than 3 words and the profile name is not Unknown
select title
from books_ratings
where review_score = 5
and length(review_text) > 5
and length(review_summary) > 3
and profile_name not like '%Unknown%';

--Query 3:List the books which price is between 2 and 4, are given rating between 1 and 3, have a valid rating date format
-- (yyyy-mm-dd) and the name of the user that has given the rating must not be Unknown or an email address.
select date_rating,profile_name
from books_ratings
where price between 2 and 4
and review_score between 1 and 3
AND (date_rating LIKE '____-__-__')
and (profile_name not like 'Unknown' and profile_name not like '%.com');

--Query 4:According to the words found in the review_summary, for every user calculate how many reviews have positive and negative reactions
select profile_name,
    count(*) as total_reviews,
    sum(case when review_summary ilike '%excellent%' or review_summary ilike '%good%' or review_summary ilike '%great%'
        or review_summary ilike '%awesome%' or review_summary ilike '%would recommend%' then 1 else 0 end) as good_reviews,
    sum(case when review_summary ilike '%did not enjoy%' or review_summary ilike '%did not like%' or review_summary ilike '%boring%'
        or review_summary ilike '%would not recommend%' or (review_summary ilike '%too bad%' and review_summary not ilike '%not%')
        then 1 else 0 end) as bad_reviews
from books_ratings
where profile_name not ilike 'Unknown' and review_score>3
group by profile_name
order by total_reviews desc;

--Query 5:List the users' information who have given ratings with helpfulness greater than 50%, including the average
--result of the given ratings for every user
select user_id,profile_name,
       count(*) as total_reviews,
       avg(review_score) as average_score
from books_ratings
where cast(substring(review_helpfulness,1,position('/' in review_helpfulness)-1) as double precision) /
      nullif(cast(substring(review_helpfulness,position('/' in review_helpfulness)+1) as double precision),0) > 0.5
group by user_id, profile_name
having count(*) >=5
order by average_score desc;

--Query 6:List the details of the books with highest average rating from the users, including the number of ratings and the
-- time of the most recent rating for the book.
select rated_books.title, average_score, total_reviews,
       most_recent_review_time, review_summary, review_text
from(
    select title,
           avg(review_score)as average_score,
           count(*) as total_reviews,
           max(review_time)as most_recent_review_time
    from books_ratings
    group by title) as rated_books
join books_ratings on rated_books.title = books_ratings.title
order by average_score desc
limit 5;

--Query 7:List the books with greatest number of ratings from anonymous users
select title,
       count(case when profile_name = 'Unknown' then 1 else 0 end)as number_of_anonymous_reviews,
       avg(review_score)as average_rating_for_anonymous_reviews,
       case
           when avg(review_score) >= 4 then 'Positive'
           when avg(review_score) < 2 then 'Negative'
           else 'Mixed'
        end as average_sentiment_for_book
from books_ratings
group by title
having count(case when profile_name='Unknown' then 1 else 0 end) > 5
order by number_of_anonymous_reviews desc;

--Query 8:List the top 10 best rated books with more than 3 reviews according to the most recent reviews, sorted by
--the average rating and the number of reviews
select br.title, br.price, br.profile_name as reviewer_name,
       avg(review_score)as average_rating,
       count(id)as number_of_reviews
from books_ratings as br,
     (
         select title,max(review_time)as latest_review_time
         from books_ratings
         group by title
     ) as latest_reviews
where br.title = latest_reviews.title and br.review_time = latest_reviews.latest_review_time
group by br.title, br.price, br.profile_name
having count(br.id) > 3
order by average_rating desc, number_of_reviews desc
limit 10;

--Query 9: List the number of books that start on "The" and that have been given rating during
--the 4 trimesters with review_score greater than 4
SELECT
  (SELECT COUNT(*)
   FROM books_ratings
   WHERE review_score > 4
     AND EXTRACT(MONTH FROM TO_DATE(date_rating, 'YYYY-MM-DD')) BETWEEN 1 AND 3
     AND title LIKE 'The%') AS num_books_above_4_first_quarter,

  (SELECT COUNT(*)
   FROM books_ratings
   WHERE review_score > 4
     AND EXTRACT(MONTH FROM TO_DATE(date_rating, 'YYYY-MM-DD')) BETWEEN 4 AND 6
     AND title LIKE 'The%') AS num_books_above_4_second_quarter,

  (SELECT COUNT(*)
   FROM books_ratings
   WHERE review_score > 4
     AND EXTRACT(MONTH FROM TO_DATE(date_rating, 'YYYY-MM-DD')) BETWEEN 7 AND 9
     AND title LIKE 'The%') AS num_books_above_4_third_quarter,

  (SELECT COUNT(*)
   FROM books_ratings
   WHERE review_score > 4
     AND EXTRACT(MONTH FROM TO_DATE(date_rating, 'YYYY-MM-DD')) BETWEEN 10 AND 12
     AND title LIKE 'The%') AS num_books_above_4_fourth_quarter;

--Query 10:List all the books which were published in the past 2 years and which review_text contain more than 60 words
select title,price,review_text,date_rating
from books_ratings
where TO_DATE(date_rating, 'YYYY-MM-DD') BETWEEN CURRENT_DATE - INTERVAL '2 year' AND CURRENT_DATE
and length(review_text) - length(replace(review_text,' ','')) + 1 > 60
order by date_rating asc ;