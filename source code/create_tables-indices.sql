use TechnoSphere_2025_DB
go

-- роли
create table roles (
    role_id smallint identity(1,1) not null,
    role_name nvarchar(50) not null,

    constraint pk_roles primary key (role_id),
    constraint uq_roles_role_name unique (role_name)
);

-- пользователи
create table users (
    user_id int identity(1,1) not null,
    role_id smallint not null,
    login nvarchar(100) not null,
    password_hash nvarchar(256) not null,
    email nvarchar(255) not null,
    created_at datetime2 not null default sysdatetime(),

    constraint pk_users primary key (user_id),
    constraint uq_users_login unique (login),
    constraint uq_users_email unique (email),
    constraint fk_users_roles
        foreign key (role_id) references roles(role_id)
);

-- категории
create table categories (
    category_id int identity(1,1) not null,
    category_name nvarchar(150) not null,
    description nvarchar(1000) null,

    constraint pk_categories primary key (category_id),
    constraint uq_categories_category_name unique (category_name)
);

-- товары
create table products (
    product_id bigint identity(1,1) not null,
    category_id int not null,
    name nvarchar(300) not null,
    brand nvarchar(150) not null,
    price decimal(12,2) not null,
    description nvarchar(max) null,
    is_available bit not null default 1,
    created_at datetime2 not null default sysdatetime(),
    popularity int not null default 0,

    constraint pk_products primary key (product_id),
    constraint fk_products_categories
        foreign key (category_id) references categories(category_id),
    constraint chk_products_price
        check (price >= 0),
);

-- типы характеристик
create table specification_types (
    specification_type_id int identity(1,1) not null,
    name nvarchar(200) not null,

    constraint pk_specification_types primary key (specification_type_id),
    constraint uq_specification_types_name unique (name)
);

-- характеристики товаров
create table product_specifications (
    product_id bigint not null,
    specification_type_id int not null,
    value nvarchar(1000) not null,

    constraint pk_product_specifications
        primary key (product_id, specification_type_id),

    constraint fk_product_specifications_products
        foreign key (product_id) references products(product_id)
        on delete cascade,

    constraint fk_product_specifications_specification_types
        foreign key (specification_type_id) references specification_types(specification_type_id)
);

-- избранное
create table favorites (
    user_id int not null,
    product_id bigint not null,
    created_at datetime2 not null default sysdatetime(),

    constraint pk_favorites
        primary key (user_id, product_id),

    constraint fk_favorites_users
        foreign key (user_id) references users(user_id)
        on delete cascade,

    constraint fk_favorites_products
        foreign key (product_id) references products(product_id)
        on delete cascade
);

-- корзина
create table basket_items (
    basket_item_id bigint identity(1,1) not null,
    user_id int not null,
    product_id bigint not null,
    quantity int not null,
    added_at datetime2 not null default sysdatetime(),

    constraint pk_basket_items primary key (basket_item_id),

    constraint fk_basket_items_users
        foreign key (user_id) references users(user_id)
        on delete cascade,

    constraint fk_basket_items_products
        foreign key (product_id) references products(product_id),

    constraint chk_basket_items_quantity
        check (quantity > 0)
);

-- статусы заказов
create table order_statuses (
    status_id tinyint identity(1,1) not null,
    status_name nvarchar(100) not null,

    constraint pk_order_statuses primary key (status_id),
    constraint uq_order_statuses_status_name unique (status_name)
);

insert into order_statuses (status_name) values ('created'), ('paid'), ('shipped'), ('delivered'), ('cancelled')

-- заказы
create table orders (
    order_id bigint identity(1,1) not null,
    user_id int not null,
    status_id tinyint not null,
    created_at datetime2 not null default sysdatetime(),
    updated_at datetime2 null,
    total_price decimal(14,2) not null default 0,
    shipping_address nvarchar(1000) not null,

    constraint pk_orders primary key (order_id),

    constraint fk_orders_users
        foreign key (user_id) references users(user_id),

    constraint fk_orders_order_statuses
        foreign key (status_id) references order_statuses(status_id),

    constraint chk_orders_total_price
        check (total_price >= 0)
);

-- товары в заказе
create table order_items (
    order_item_id bigint identity(1,1) not null,
    order_id bigint not null,
    product_id bigint not null,
    quantity int not null,
    unit_price decimal(12,2) not null,

    constraint pk_order_items primary key (order_item_id),

    constraint fk_order_items_orders
        foreign key (order_id) references orders(order_id)
        on delete cascade,

    constraint fk_order_items_products
        foreign key (product_id) references products(product_id),

    constraint chk_order_items_quantity
        check (quantity > 0),

    constraint chk_order_items_unit_price
        check (unit_price >= 0)
);

create unique nonclustered index ix_roles_role_name on roles (role_name);
create unique nonclustered index ix_users_login on users (login);
create unique nonclustered index ix_users_email on users (email);
create nonclustered index ix_users_role_id on users (role_id);
create unique nonclustered index ix_categories_category_name on categories (category_name);
create nonclustered index ix_products_category_id on products (category_id);
create nonclustered index ix_products_brand on products (brand);
create nonclustered index ix_products_price on products (price);
create nonclustered index ix_products_created_at on products (created_at desc);
create nonclustered index ix_products_popularity on products (popularity desc);
create nonclustered index ix_products_category_price on products (category_id, price);
create nonclustered index ix_products_category_brand on products (category_id, brand);
create unique nonclustered index ix_specification_types_name on specification_types (name);
create nonclustered index ix_product_specifications_product_id on product_specifications (product_id);
create nonclustered index ix_favorites_user_id on favorites (user_id);
create nonclustered index ix_basket_items_user_id on basket_items (user_id);
create unique nonclustered index ix_order_statuses_status_name on order_statuses (status_name);
create nonclustered index ix_orders_user_id on orders (user_id);
create nonclustered index ix_orders_user_created_at on orders (user_id, created_at desc);
create nonclustered index ix_order_items_order_id on order_items (order_id);

create nonclustered index ix_products_category_price_popularity on dbo.products (category_id, price, popularity);
create nonclustered index ix_products_popularity_desc on dbo.products(popularity desc);