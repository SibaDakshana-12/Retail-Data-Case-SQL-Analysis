import streamlit as st
import pandas as pd
import plotly.express as px

st.set_page_config(
    page_title="Retail Analytics Dashboard",
    page_icon="📊",
    layout="wide"
)

# -----------------------------
# Load data
# -----------------------------

@st.cache_data
def load_data():
    customers = pd.read_csv("Customer.csv")
    products = pd.read_csv("prod_cat_info.csv")
    transactions = pd.read_csv("Transactions.csv")

    products = products.rename(columns={
        "prod_sub_cat_code": "prod_subcat_code"
    })

    transactions = transactions.rename(columns={
        "Store_type": "store_type"
    })

    transactions["tran_date"] = pd.to_datetime(
        transactions["tran_date"],
        errors="coerce"
    )

    products = products.drop_duplicates(
        subset=["prod_cat_code", "prod_subcat_code"]
    )

    transactions = transactions.merge(
        products,
        on=["prod_cat_code", "prod_subcat_code"],
        how="left"
    )

    transactions = transactions.merge(
        customers[["customer_Id", "Gender", "city_code", "DOB"]],
        left_on="cust_id",
        right_on="customer_Id",
        how="left"
    )

    return customers, products, transactions


customers, products, transactions = load_data()


# Sidebar
st.sidebar.header("Filters")

categories = sorted(
    transactions["prod_cat"].dropna().unique()
)


# -----------------------------
# Title
# -----------------------------

st.title("📊 Retail Analytics Dashboard")
st.caption(
    "Interactive analysis of customer behavior, product performance, "
    "sales, returns, and store performance."
)


# -----------------------------
# Sidebar filters
# -----------------------------

st.sidebar.header("Filters")

categories = sorted(
    transactions["prod_cat"].dropna().unique()
)

selected_categories = st.sidebar.multiselect(
    "Product Category",
    categories,
    default=categories
)

store_types = sorted(
    transactions["store_type"].dropna().unique()
)

selected_stores = st.sidebar.multiselect(
    "Store Type",
    store_types,
    default=store_types
)

filtered = transactions[
    transactions["prod_cat"].isin(selected_categories)
    & transactions["store_type"].isin(selected_stores)
].copy()


# -----------------------------
# KPI calculations
# -----------------------------

total_revenue = filtered["total_amt"].sum()
total_transactions = filtered["transaction_id"].nunique()
quantity_sold = filtered["Qty"].sum()

return_value = filtered.loc[
    filtered["total_amt"] < 0,
    "total_amt"
].abs().sum()


# -----------------------------
# KPI cards
# -----------------------------

col1, col2, col3, col4 = st.columns(4)

col1.metric(
    "Net Revenue",
    f"₹{total_revenue:,.0f}"
)

col2.metric(
    "Transactions",
    f"{total_transactions:,}"
)

col3.metric(
    "Quantity Sold",
    f"{quantity_sold:,}"
)

col4.metric(
    "Return Value",
    f"₹{return_value:,.0f}"
)


st.divider()


# -----------------------------
# Sales Analysis
# -----------------------------

st.header("Sales Analysis")

col1, col2 = st.columns(2)

with col1:

    category_sales = (
        filtered.groupby("prod_cat", as_index=False)
        ["total_amt"]
        .sum()
        .sort_values("total_amt", ascending=False)
    )

    fig = px.bar(
        category_sales,
        x="prod_cat",
        y="total_amt",
        title="Revenue by Category",
        labels={
            "prod_cat": "Category",
            "total_amt": "Revenue"
        }
    )

    st.plotly_chart(fig, use_container_width=True)


with col2:

    store_sales = (
        filtered.groupby("store_type", as_index=False)
        ["total_amt"]
        .sum()
        .sort_values("total_amt", ascending=False)
    )

    fig = px.bar(
        store_sales,
        x="store_type",
        y="total_amt",
        title="Revenue by Store Type",
        labels={
            "store_type": "Store Type",
            "total_amt": "Revenue"
        }
    )

    st.plotly_chart(fig, use_container_width=True)


# -----------------------------
# Monthly Revenue
# -----------------------------

monthly_sales = (
    filtered
    .dropna(subset=["tran_date"])
    .assign(
        month=lambda x: x["tran_date"].dt.to_period("M").astype(str)
    )
    .groupby("month", as_index=False)["total_amt"]
    .sum()
)

fig = px.line(
    monthly_sales,
    x="month",
    y="total_amt",
    markers=True,
    title="Monthly Revenue Trend",
    labels={
        "month": "Month",
        "total_amt": "Revenue"
    }
)

st.plotly_chart(fig, use_container_width=True)


# -----------------------------
# Product Analysis
# -----------------------------

st.header("Product Analysis")

col1, col2 = st.columns(2)

with col1:

    top_subcategories = (
        filtered.groupby("prod_subcat", as_index=False)
        ["total_amt"]
        .sum()
        .sort_values("total_amt", ascending=False)
        .head(10)
    )

    fig = px.bar(
        top_subcategories.sort_values("total_amt"),
        x="total_amt",
        y="prod_subcat",
        orientation="h",
        title="Top 10 Subcategories by Revenue",
        labels={
            "prod_subcat": "Subcategory",
            "total_amt": "Revenue"
        }
    )

    st.plotly_chart(fig, use_container_width=True)


with col2:

    category_quantity = (
        filtered.groupby("prod_cat", as_index=False)
        ["Qty"]
        .sum()
        .sort_values("Qty", ascending=False)
    )

    fig = px.bar(
        category_quantity,
        x="prod_cat",
        y="Qty",
        title="Quantity Sold by Category",
        labels={
            "prod_cat": "Category",
            "Qty": "Quantity Sold"
        }
    )

    st.plotly_chart(fig, use_container_width=True)


# -----------------------------
# Customer Analysis
# -----------------------------

st.header("Customer Analysis")

col1, col2 = st.columns(2)

with col1:

    gender_data = (
        filtered.groupby("Gender", as_index=False)
        ["cust_id"]
        .nunique()
        .rename(columns={"cust_id": "customers"})
    )

    fig = px.pie(
        gender_data,
        names="Gender",
        values="customers",
        title="Customers by Gender"
    )

    st.plotly_chart(fig, use_container_width=True)


with col2:

    city_data = (
        filtered.groupby("city_code", as_index=False)
        ["cust_id"]
        .nunique()
        .rename(columns={"cust_id": "customers"})
        .sort_values("customers", ascending=False)
        .head(10)
    )

    fig = px.bar(
        city_data.sort_values("customers"),
        x="customers",
        y="city_code",
        orientation="h",
        title="Top 10 Cities by Customers",
        labels={
            "city_code": "City Code",
            "customers": "Customers"
        }
    )

    st.plotly_chart(fig, use_container_width=True)


# -----------------------------
# Return Analysis
# -----------------------------

st.header("Return Analysis")

returns = filtered[filtered["total_amt"] < 0].copy()

col1, col2 = st.columns(2)

with col1:

    category_returns = (
        returns.groupby("prod_cat", as_index=False)
        ["total_amt"]
        .apply(lambda x: x.abs().sum())
        .rename(columns={"total_amt": "return_value"})
        .sort_values("return_value", ascending=False)
    )

    fig = px.bar(
        category_returns,
        x="prod_cat",
        y="return_value",
        title="Return Value by Category",
        labels={
            "prod_cat": "Category",
            "return_value": "Return Value"
        }
    )

    st.plotly_chart(fig, use_container_width=True)


with col2:

    monthly_returns = (
        returns
        .dropna(subset=["tran_date"])
        .assign(
            month=lambda x: x["tran_date"].dt.to_period("M").astype(str)
        )
        .groupby("month", as_index=False)["total_amt"]
        .apply(lambda x: x.abs().sum())
        .rename(columns={"total_amt": "return_value"})
    )

    fig = px.line(
        monthly_returns,
        x="month",
        y="return_value",
        markers=True,
        title="Monthly Return Trend",
        labels={
            "month": "Month",
            "return_value": "Return Value"
        }
    )

    st.plotly_chart(fig, use_container_width=True)


# -----------------------------
# Summary table
# -----------------------------

st.header("Category Performance")

summary = (
    filtered.groupby("prod_cat", as_index=False)
    .agg(
        Revenue=("total_amt", "sum"),
        Quantity_Sold=("Qty", "sum"),
        Transactions=("transaction_id", "nunique")
    )
    .sort_values("Revenue", ascending=False)
)

st.dataframe(
    summary,
    use_container_width=True,
    hide_index=True
)