use TechnoSphere_2025
go

-- роли
create table roles (
    role_id smallint identity(1,1) primary key,
    role_name nvarchar(50) not null unique
)

insert into roles (role_name) values ('admin'), ('user')

-- пользователи
create table users (
    user_id int identity(1,1) primary key,
    login nvarchar(100) not null unique,
    password_hash nvarchar(256) not null,
    email nvarchar(255) not null unique,
    role_id smallint not null,
    created_at datetime2 not null default sysdatetime(),
    constraint fk_users_roles foreign key (role_id) references roles(role_id)
)

-- категории
create table categories (
    category_id int identity(1,1) primary key,
    category_name nvarchar(150) not null unique,
    description nvarchar(1000) null
)

-- товары
create table products (
    product_id bigint identity(1,1) primary key,
    category_id int not null,
    name nvarchar(300) not null,
    brand nvarchar(150) not null,
    price decimal(12,2) not null check (price >= 0),
    description nvarchar(max) null,
    is_available bit not null default 1,
    created_at datetime2 not null default sysdatetime(),
    average_rating decimal(3,2) null, -- поддерживается триггером
    popularity int not null default 0, -- счётчик продаж/просмотров
    constraint fk_products_categories foreign key (category_id) references categories(category_id)
)

-- типы характеристик
create table specification_types (
    specification_type_id int identity(1,1) primary key,
    name nvarchar(200) not null unique
)

-- характеристики товаров
create table product_specifications (
    product_id bigint not null,
    specification_type_id int not null,
    value nvarchar(1000) not null,
    primary key (product_id, specification_type_id),
    constraint fk_ps_products foreign key (product_id) references products(product_id) on delete cascade,
    constraint fk_ps_types foreign key (specification_type_id) references specification_types(specification_type_id) on delete no action
)

-- избранное
create table favorites (
    user_id int not null,
    product_id bigint not null,
    created_at datetime2 not null default sysdatetime(),
    primary key (user_id, product_id),
    constraint fk_fav_user foreign key (user_id) references users(user_id) on delete cascade,
    constraint fk_fav_product foreign key (product_id) references products(product_id) on delete cascade
)

-- корзина
create table basket_items (
    basket_item_id bigint identity(1,1) primary key,
    user_id int not null,
    product_id bigint not null,
    quantity int not null check (quantity > 0),
    added_at datetime2 not null default sysdatetime(),
    constraint fk_basket_user foreign key (user_id) references users(user_id) on delete cascade,
    constraint fk_basket_product foreign key (product_id) references products(product_id) on delete no action
)

-- статусы заказов
create table order_statuses (
    status_id tinyint identity(1,1) primary key,
    status_name nvarchar(100) not null unique
)

insert into order_statuses (status_name) values ('created'), ('paid'), ('shipped'), ('delivered'), ('cancelled')

-- заказы
create table orders (
    order_id bigint identity(1,1) primary key,
    user_id int not null,
    status_id tinyint not null default 1,
    created_at datetime2 not null default sysdatetime(),
    updated_at datetime2 null,
    total_price decimal(14,2) not null default 0,
    shipping_address nvarchar(1000) null,
    constraint fk_orders_user foreign key (user_id) references users(user_id) on delete no action,
    constraint fk_orders_status foreign key (status_id) references order_statuses(status_id) on delete no action
)

-- товары в заказе
create table order_items (
    order_item_id bigint identity(1,1) primary key,
    order_id bigint not null,
    product_id bigint not null,
    quantity int not null check (quantity > 0),
    unit_price decimal(12,2) not null check (unit_price >= 0),
    constraint fk_oi_order foreign key (order_id) references orders(order_id) on delete cascade,
    constraint fk_oi_product foreign key (product_id) references products(product_id) on delete no action
)

-- отзывы на товары
create table product_reviews (
    review_id bigint identity(1,1) primary key,
    user_id int not null,
    product_id bigint not null,
    rating tinyint not null check (rating >= 1 and rating <= 5),
    comment nvarchar(max) null,
    created_at datetime2 not null default sysdatetime(),
    constraint fk_pr_user foreign key (user_id) references users(user_id) on delete cascade,
    constraint fk_pr_product foreign key (product_id) references products(product_id) on delete cascade,
    constraint ux_user_product_review unique (user_id, product_id)
)

create index idx_products_category_price on products (category_id, price)
create index idx_products_brand on products (brand)
create index idx_products_price on products (price)
create index idx_products_name_fulltext on products (name)

create index idx_order_items_orderid on order_items (order_id)
create index idx_basket_user on basket_items (user_id)
create index idx_favorites_user on favorites (user_id)
create index idx_reviews_product on product_reviews (product_id)