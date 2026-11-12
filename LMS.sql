CREATE DATABASE library;
USE library;
CREATE TABLE books(
book_id INT AUTO_INCREMENT PRIMARY KEY,
book_name VARCHAR(100),
book_author varchar(100),
book_price decimal(10,2),
total_copies int not null);
show tables;
describe books;

insert into books (book_name, book_author, book_price, total_copies)
values ('java beginner', 'sam',200.00, 10),
('DSA', 'joseph',200.00,6),
('HTML and CSS', 'Robert', 300.00, 6),
('Java Advanced', 'James', 600.00, 2);
select*from books;

create table users(
user_id int auto_increment primary key,
user_name varchar(100),
user_email varchar(100) unique,
user_phonenum int,
membership_date date);
describe users;

insert into users(user_name, user_email, user_phonenum, membership_date)
values
('Rahul', 'rahul@gmail.com', '98765', '2026-11-12'),
('Arun', 'arun@gmail.com', '998754', '2026-11-12'),
('Priya', 'priya@gmail.com', '98765', '2026-11-12');
select*from users;

create table transaction(
trans_id int auto_increment primary key,
user_id int not null,
book_id int not null,
issued_date date,
return_date date,
due_date date,
status varchar(30) not null default 'issued',
foreign key(user_id) references users(user_id),
foreign key(book_id) references books(book_id));

describe transaction;

select*from books;
select*from users;

insert into transaction(user_id,book_id,issued_date,due_date,status)
values(1, 1, '2026-11-12', '2026-11-26', 'Issued');
select*from transaction;
select
users.user_name,
books.book_name,
transaction.issued_date,
transaction.due_date,
transaction.status
from transaction
inner join users
on transaction.user_id=users.user_id
inner join books
on transaction.book_id=books.book_id;

select
users.user_name,
transaction.trans_id
from users
left join transaction
on users.user_id=transaction.user_id

select
users.user_name,
transaction.trans_id
from users
right join transaction
on users.user_id = transaction.user_id;

insert into transaction
(user_id, book_id, issued_date, due_date, status)
values
(2, 2, '2026-11-12', '2026-11-26', 'Issued');

select
users.user_name,
transaction.trans_id
from users
left join transaction
on users.user_id = transaction.user_id
union
select
users.user_name,
transaction.trans_id
from users
right join transaction
on users.user_id = transaction.user_id;

select
users.user_name,
books.book_name,
transaction.status
from users
left join transaction
on users.user_id = transaction.user_id
left join books
on transaction.book_id = books.book_id;

Alter table transaction
add column fine_amount decimal(10,2) default 0.00,
add column fine_paid boolean default false;

alter table users modify user_phonenum VARCHAR(15);
update transaction
SET
return_date = '2026-11-18',
fine_amount = GREATEST(
datediff('2026-11-18', due_date), 0) * 5
where trans_id = 1;

select
trans_id,user_id,book_id,due_date,return_date,fine_amount,fine_paid
from transaction;

update transaction
set return_date = '2026-11-18', status = 'Returned'
where trans_id = 1;
select * from transaction;

update transaction
set
return_date = '2026-11-30',
status = 'Returned',
fine_amount = greatest(
datediff('2026-11-30', due_date), 0) * 5
where trans_id = 2;

select
trans_id,due_date,return_date,status,fine_amount,fine_paid
from transaction;

alter table books
add available_copies int not null default 0;
update books
set available_copies = total_copies where book_id>0;

select book_name,total_copies,available_copies
from books;

select available_copies from books
where book_id = 1;

insert into transaction(user_id, book_id, issued_date, due_date, status)
values (1, 1, '2026-11-12', '2026-11-26', 'Issued');

update books set available_copies = available_copies - 1
where book_id = 1
and available_copies > 0;

select * from `transaction`
where user_id = 1
and book_id = 1
and status = 'Issued';

update transaction
set return_date = '2026-11-12',status = 'Returned',
fine_amount = greatest(
datediff('2026-11-12', due_date), 0) * 5
where trans_id = 3
and status = 'Issued';
update books
set available_copies = available_copies + 1
where book_id = 1;

show table status
where Name in ('books', 'users', 'transaction');

start transaction;

update books
set available_copies = available_copies - 1
where book_id = 1;
rollback;

select book_name, total_copies, available_copies
from books
where book_id = 1;

start transaction;
select available_copies
from books
where book_id = 1
for update;

insert into transaction
(user_id, book_id, issued_date, due_date, status)
select 1,1,current_date(),
date_add(current_date(), interval 14 day),'Issued'
where exists (
    select 1 from users where user_id = 1
)
and exists (
    select 1 from books
    where book_id = 1
    and available_copies > 0
);
update books
set available_copies = available_copies - 1
where book_id = 1
and available_copies > 0
and exists (
    select 1 from users where user_id = 1
)
and exists (
    select 1 from transaction
    where user_id = 1
    and book_id = 1
    and status = 'Issued'
    AND issued_date = CURRENT_DATE()
);
commit;
select * from books where book_id = 1;
select * from transaction
order by trans_id desc;

update books
set available_copies = total_copies - (select count(*) from transaction
where transaction.book_id = books.book_id and transaction.status = 'Issued'
)where book_id > 0;
select
book_id,
book_name,
total_copies,
available_copies
from books;

drop procedure if exists borrow_book;
DELIMITER //
create procedure borrow_book(
in p_user_id int,
in p_book_id int
)
begin
declare v_user_count int default 0;
declare v_book_count int default 0;
declare v_available int default 0;
declare v_rows int default 0;
declare exit handler for sqlexception
begin
rollback;
resignal;
end;

start transaction;
select count(*)
into v_user_count
from users
where user_id = p_user_id;

if v_user_count = 0 then
signal sqlstate '45000'
set message_text= 'User does not exist';
end if;

select count(*)
into v_book_count
from books
where book_id = p_book_id;

if v_book_count = 0 THEN
signal sqlstate'45000'
set message_text = 'Book does not exist';
end if;

select available_copies
into v_available
from books
where book_id = p_book_id
for update;
if v_available <= 0 then
signal sqlstate '45000'
set message_text = 'Book is not available';
end if;

insert into transaction(user_id,book_id,issued_date,due_date,status)
values(p_user_id,p_book_id,current_date(),date_add(current_date(), interval 14 day),'Issued');

update books
set available_copies = available_copies - 1
where book_id = p_book_id
and available_copies > 0;

set v_rows = row_count();
if v_rows <> 1 then
signal sqlstate'45000'
set message_text= 'Stock update failed';
end if;
commit;
end //
delimiter ;

drop procedure if exists return_book;

delimiter //

create procedure return_book(in p_trans_id int)
begin
declare v_trans_count int default 0;
declare v_book_id int;
declare v_due_date date;
declare v_status varchar(30);
declare v_fine decimal(10,2);
declare v_rows int default 0;

declare exit handler for sqlexception
begin
rollback;
resignal;
end;

start transaction;

select count(*)
into v_trans_count
from transaction
where trans_id = p_trans_id;

if v_trans_count = 0 then
signal sqlstate '45000'
set message_text = 'Transaction does not exist';
end if;

select book_id, due_date, status
into v_book_id, v_due_date, v_status
from transaction
where trans_id = p_trans_id
for update;

if v_status <> 'Issued' THEN
 signal sqlstate '45000'
set message_text = 'Book is already returned';
end if;

select available_copies
into v_rows
from books
where book_id = v_book_id
for update;

set v_fine =greatest(datediff(CURRENT_DATE(), v_due_date), 0) * 5;

update transaction
set
return_date = current_date(),
status = 'Returned',
fine_amount = v_fine,
fine_paid = case
when v_fine = 0 then true
else false
end
where trans_id = p_trans_id
and status = 'Issued';
set v_rows = row_count();
if v_rows <> 1 then
signal sqlstate '45000'
set message_text = 'Return update failed';
end if;

update books
set available_copies = available_copies + 1
where book_id = v_book_id;

set v_rows = row_count();

if v_rows <> 1 then
signal sqlstate '45000'
set message_text = 'Book stock update failed';
end if;
commit;
end //

DELIMITER  ;

call borrow_book(1, 1);
call return_book(4);
select book_id,book_name,total_copies,available_copies
from books;

select t.trans_id,u.user_name,b.book_name,t.issued_date,t.due_date,t.return_date,t.status,t.fine_amount,t.fine_paid
from transaction t
inner join users u
on t.user_id = u.user_id
inner join books b
on t.book_id = b.book_id
order by t.trans_id desc;

