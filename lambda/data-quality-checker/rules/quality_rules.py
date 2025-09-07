# lambda/data-quality-checker/rules/quality_rules.py

# --- SQL Data Quality Rules ---
# These rules are executed by the AWS Glue Job using Spark SQL.
# Key: Rule Name (for identification)
# Value: Dictionary containing 'query', 'error_type', and 'description'
SQL_DATA_QUALITY_RULES = {
    "null_user_id_check": {
        "query": "SELECT * FROM temp_data WHERE user_id IS NULL",
        "error_type": "NULL_USER_ID",
        "description": "Checks for records where 'user_id' is NULL."
    },
    "invalid_email_format_check": {
        "query": "SELECT * FROM temp_data WHERE email NOT RLIKE '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'",
        "error_type": "INVALID_EMAIL_FORMAT",
        "description": "Checks for records where 'email' does not match a standard email regex pattern."
    },
    "duplicate_order_id_check": {
        "query": "SELECT order_id, COUNT(*) FROM temp_data GROUP BY order_id HAVING COUNT(*) > 1",
        "error_type": "DUPLICATE_ORDER_ID",
        "description": "Checks for duplicate 'order_id' values."
    }
    # Add more SQL rules as needed
}

# --- Python Data Quality Rules ---
# These rules are executed by the AWS Lambda function.
# Each function should take a single record (dictionary) as input
# and return a dictionary of error details if a problem is found,
# or None if the record passes the check.

def check_product_category_valid(record):
    """
    Checks if the 'product_category' is one of the predefined valid categories.
    """
    valid_categories = ["Electronics", "Books", "Clothing", "Home & Kitchen"]
    if record.get('product_category') not in valid_categories:
        return {
            "error_type": "INVALID_PRODUCT_CATEGORY",
            "description": f"Invalid product category: {record.get('product_category')}",
            "record_id": record.get('id') # Assuming 'id' is a unique identifier
        }
    return None

def check_price_positive(record):
    """
    Checks if the 'price' is a positive number.
    """
    price = record.get('price')
    if not isinstance(price, (int, float)) or price <= 0:
        return {
            "error_type": "NON_POSITIVE_PRICE",
            "description": f"Price is not positive: {price}",
            "record_id": record.get('id')
        }
    return None

# List of Python rule functions to be applied
PYTHON_DATA_QUALITY_RULES = [
    check_product_category_valid,
    check_price_positive,
    # Add more Python rule functions here
]

# --- Helper Functions ---

def get_sql_rules():
    """Returns the dictionary of SQL data quality rules."""
    return SQL_DATA_QUALITY_RULES

def get_python_rules():
    """Returns the list of Python data quality rule functions."""
    return PYTHON_DATA_QUALITY_RULES