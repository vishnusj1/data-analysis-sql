CREATE TABLE Staging_Sales (
    "Order Number" VARCHAR(255),
    "Line Item" VARCHAR(255),
    "Order Date" VARCHAR(255),
    "Delivery Date" VARCHAR(255),
    CustomerKey VARCHAR(255),
    StoreKey VARCHAR(255),
	ProductKey VARCHAR(255),
	Quantity VARCHAR(255),
	"Currency Code" VARCHAR(255)
);

CREATE TABLE Staging_Customers (
    CustomerKey VARCHAR(255),
    Gender VARCHAR(255),
    Name VARCHAR(255),
	City VARCHAR(255),
    "State Code" VARCHAR(255),
    State VARCHAR(255),
    "Zip Code" VARCHAR(255),
	Country VARCHAR(255),
	Continent VARCHAR(255),
	Birthday VARCHAR(255)
);

CREATE TABLE Staging_Products (
	ProductKey VARCHAR(255), 
	"Product Name" VARCHAR(255),
	Brand VARCHAR(255),
	Color VARCHAR(255),
    "Unit Cost USD" VARCHAR(255),
    "Unit Price USD" VARCHAR(255),
    SubcategoryKey VARCHAR(255),
    Subcategory VARCHAR(255),
    CategoryKey VARCHAR(255),
    Category VARCHAR(255)
);

CREATE TABLE Staging_Stores (
    StoreKey VARCHAR(255),
    Country VARCHAR(255),
    State VARCHAR(255),
    "Square Meters" VARCHAR(255),
    OpenDate VARCHAR(255)
);

CREATE TABLE Staging_Exchange_Rates (
    Date VARCHAR(255),
    Currency VARCHAR(255),
    Exchange VARCHAR(255)
);


