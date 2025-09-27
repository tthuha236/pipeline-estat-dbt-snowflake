import pandas as pd
import streamlit as st
import plotly.express as px
import snowflake.connector
from streamlit_plotly_events import plotly_events
import boto3
import json


st.set_page_config(
    page_title="二人以上の勤労世帯の家計支出ダッシュボード",
    layout="wide"
)

#-------------Snowflake connection-------------
def get_secret(secret_name, region_name):
    # create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )
    response = client.get_secret_value(SecretId=secret_name)
    secret = response['SecretString']
    return json.load(secret)

@st.cache_resource(show_spinner=False)
def get_conn():
    cfg = get_secret("streamlit/connections/snowflake","ap-northeast-1")
    return snowflake.connector.connect(
        user=cfg["user"],
        password=cfg["password"],
        account=cfg["account"],
        warehouse=cfg["warehouse"],
        database=cfg["database"],
        schema=cfg["schema"],
        client_session_keep_alive=True
    )

@st.cache_data(show_spinner=True, ttl=600)
def load_data(tables_list):
    """Load expense summary data from snowflake"""
    conn = get_conn()
    # load expense summary by main category
    results = {}
    for table in tables_list:
        q = f"select *, TO_VARCHAR(year) || '/' || LPAD(month::string, 2, '0') AS ym_str from {table}"
        cur = conn.cursor().execute(q)
        cols = [c[0].lower() for c in cur.description]
        df = pd.DataFrame(cur.fetchall(), columns=cols)
        results[table] = df
        cur.close()
    return results

@st.cache_data(show_spinner=False, ttl=600)
def load_dim_values(main_df, region_col, city_col, ym_col, category_col):
    """Load lists for filters: regions, cities, categories, months range"""
    # min year, max year, min month, max month
    # min_ym = main_df[ym_col].min().dt.strftime("%Y/%m")
    # max_ym = main_df[ym_col].max().dt.strftime("%Y/%m")
    months = sorted(main_df[ym_col].unique(), reverse=True)
    regions = main_df[region_col].unique().tolist()
    cities = main_df[city_col].unique().tolist()
    categories = main_df[category_col].unique().tolist()
    return {
        "months": months,
        "regions": regions,
        "cities": cities,
        "categories": categories
    }


# ------------------ UI: filters -------------------
st.title("家計消費支出ダッシュボード")
st.markdown(
    """
    <style>
    /* Whole app background */
    .main {
        background-color: #f0f0f0;   /* light gray */
    }
    </style>
    """,
    unsafe_allow_html=True
)

# load data from snowflake
tables_list = ["agg_expense_by_main_category","agg_expense_by_sub_category"]
region_col="chihou"
city_col="ken_name"
ym_col="ym_str"
category_col="main_category_name"
sub_category_col="sub_category_name"

if "tables" not in st.session_state:
    with st.spinner("データを読み込み中..."):
        st.session_state.tables = load_data(tables_list)
tables = st.session_state.tables
monthly_expense_df = tables[tables_list[0]]
sub_monthly_expense_df = tables[tables_list[1]]

dim = load_dim_values(tables[tables_list[0]], 
                                region_col=region_col,
                                city_col=city_col,
                                ym_col=ym_col,
                                category_col=category_col)
available_cities = dim["cities"]
colF1, colF2, colF3, colF4 = st.columns([2, 2, 1.5, 1.5], gap="small")
with colF1:
    start_ym = st.selectbox("期間開始", dim["months"],index=0)
with colF2:
    end_ym = st.selectbox("期間終了", dim["months"],index=0)
with colF3:
    region = st.selectbox("地方", options=["全て"] + dim["regions"])
    if region !="全て": available_cities = ( monthly_expense_df[monthly_expense_df[region_col] == region][city_col]
                                                .unique().tolist())
with colF4:
    city = st.selectbox("都道府県", options=["全て"] + available_cities)

if start_ym > end_ym:
    st.warning("期間開始は期間終了と同じかそれ以前の日付である必要があります")
    st.stop()

# --------------------- Metrics & charts -------------------------

st.markdown("<div style='margin-top:40px'></div>", unsafe_allow_html=True)
st.markdown(
    """
    <style>
    /* Give every subheader an underline spanning the container width */
    div[data-testid="stVerticalBlock"] h3 {
        border-bottom: 2px solid #d3d3d3;   /* line color and thickness */
        padding-bottom: 0.3rem;              /* spacing between text and line */
        margin-bottom: 1rem;                 /* spacing after the line */
    }
    </style>
    """,
    unsafe_allow_html=True
)


# filter data
filtered_df = monthly_expense_df[(monthly_expense_df[ym_col] >= start_ym) & (monthly_expense_df[ym_col] <= end_ym)]
sub_filtered_df = sub_monthly_expense_df[(sub_monthly_expense_df[ym_col] >= start_ym) & (sub_monthly_expense_df[ym_col] <= end_ym)]
amount_col = "amount"

if region != "全て": 
    filtered_df = filtered_df[filtered_df[region_col] == region]
    sub_filtered_df = sub_filtered_df[sub_filtered_df[region_col] == region]
if city != "全て": 
    filtered_df = filtered_df[filtered_df[city_col] == city]
    sub_filtered_df = sub_filtered_df[sub_filtered_df[city_col] == city]


left, divider, right = st.columns([1, 0.03, 1], gap="medium")
# Left: Metrics & Time series data
with left:
    st.subheader("支出指標")
    # -----1. Display main metrics
    st.markdown(
    """
    <style>
    /* Give every metric its own border and padding */
    div[data-testid="stMetric"] {
        border: 1px solid #d3d3d3;
        border-radius: 8px;
        padding: 1rem;
        background-color: #f9f9f9;  /* optional light background */
        margin-bottom: 1rem;        /* spacing between metrics */
    }
    </style>
    """,
      unsafe_allow_html=True
)
    # 1.1. avg monthly expense for the selected period
    monthly_total_by_city = filtered_df.groupby([city_col, region_col, ym_col], as_index=False)[amount_col].sum()
    monthly_avg_by_month = monthly_total_by_city.groupby(ym_col)[amount_col].mean()
    monthly_avg = monthly_avg_by_month.mean()

    # 1.2. decide what the 2nd metric shows
    mcol1, mcol2 = st.columns(2)
    with mcol1:
        st.metric("選択期間の月平均支出", f"{monthly_avg:,.0f}円")
    with mcol2:
        city_count = monthly_total_by_city[city_col].nunique()
        if city_count > 1:
            city_avg = (
                monthly_total_by_city.groupby(city_col)[amount_col]
                    .mean()
                    .sort_values(ascending=False)
            )
            top_city = city_avg.index[0]
            top_city_avg = city_avg.iloc[0]
            st.metric("最高平均支出の都市", f"{top_city}: {top_city_avg:,.0f}円")
        else:
            peak_month = monthly_avg_by_month.idxmax()
            peak_amount = monthly_avg_by_month.max()
            st.metric("最高支出月", f"{peak_month}:{peak_amount:,.0f}円")
    st.markdown("<div style='margin-top:40px'></div>", unsafe_allow_html=True)
    # ----2. Display trend graph
    st.markdown("### 支出トレンド")

    # Filter options for region and city inside left panel
    colR1, colR2 = st.columns(2)
    filtered_df2 = monthly_total_by_city.copy()
    with colR1:
        region_list =  filtered_df2[region_col].unique().tolist()
        region_filter = st.multiselect(
            "地方フィルター",
            options=region_list
        )
        if len(region_filter):
            filtered_df2 = filtered_df2[filtered_df2[region_col].isin(region_filter)]
    with colR2:
        city_list = filtered_df2[city_col].unique().tolist()
        city_filter = st.multiselect(
            "都道府県フィルター",
            options=city_list
        )
        if len(city_filter):
            filtered_df2 = filtered_df2[filtered_df2[city_col].isin(city_filter)]

    # number of unique months in the filtered data
    months_count = filtered_df2[ym_col].nunique()
    if months_count == 1:
        # -- 1 month selected: bar chart
        month_label = filtered_df2.iloc[0][ym_col]
        if len(region_filter) or len(city_filter):
            print("*"*20)
            # show comparison of selected city
            bar_data = (
                filtered_df2.groupby(city_col, as_index=False)[amount_col]
                        .mean()
                        .sort_values(amount_col, ascending=False)
            )
            fig = px.bar(bar_data, x=city_col, y=amount_col,
                        title=f"{month_label} 都道府県別　平均支出額",
                        labels={city_col: "県名", amount_col:"平均支出(円)" })
            fig.update_traces(hovertemplate='地域: %{x}<br>平均支出: %{y:,.0f} 円<extra></extra>')
        else:
            bar_data = (
                filtered_df2.groupby([region_col,ym_col], as_index=False)[amount_col].mean()
                        .groupby(region_col, as_index=False)[amount_col].mean()
                        .sort_values(amount_col, ascending=False)
            )
            fig = px.bar(bar_data, x=region_col, y=amount_col,
                        title=f"{month_label} 地方別　平均支出",
                        labels={region_col: "地方", amount_col: "平均支出(円)"})
            fig.update_traces(hovertemplate='地域: %{x}<br>平均支出: %{y:,.0f} 円<extra></extra>')
    else:
        if not len(city_filter) and city=="全て":
            line_data = (
                filtered_df2.groupby([ym_col,region_col], as_index=False)[amount_col]
                        .mean()
            )
            fig = px.line(line_data, x=ym_col,y=amount_col,color=region_col,markers=True,
                            title="地域別　月平均支出の推移",
                            labels={ym_col:"年月",amount_col:"平均支出(円)",region_col:"地方"})
            fig.update_traces(line_shape="spline",hovertemplate="年月: %{x}<br>地方: %{fullData.name}<br>平均支出: %{y:,.0f} 円<extra></extra>")
        else:
            line_data = (
                filtered_df2.groupby([ym_col, city_col], as_index=False)[amount_col].mean()
            )
            fig = px.line(line_data, x=ym_col,y=amount_col,color=city_col,markers=True,
                        title="都道府県別 月平均支出の推移",
                        labels={ym_col:"年月",amount_col:"平均支出(円)",city_col:"都道府県"}
            )
            fig.update_traces(line_shape="spline",hovertemplate="年月: %{x}<br>都道府県: %{fullData.name}<br>平均支出: %{y:,.0f} 円<extra></extra>")
    fig.update_layout(height=600, hoverlabel=dict(font_size=16))
    st.plotly_chart(fig, use_container_width=True, theme="streamlit")
with divider:
    # Use CSS to stretch the border to match the tallest neighbour
    st.markdown(
        """
        <div style="
            border-left: 1px solid #d3d3d3;
            height: 100%;
            min-height: 1000px;  /* force a visible height */
        "></div>
        """,
        unsafe_allow_html=True
    )

with right:
    st.subheader("支出項目別 平均支出構成")

    # Compute average contribution of each main category
    # Average expense per month for each main category
    avg_by_category = filtered_df.groupby(category_col, as_index=False)[amount_col].mean()

    # Total average monthly expense (across all categories)
    total_avg = avg_by_category[amount_col].sum()

    # Add percentage contribution column
    avg_by_category["percentage"] = avg_by_category[amount_col]/ total_avg * 100


    # create donut chart with value and percentage
    fig = px.pie(
        avg_by_category,
        names=category_col,
        values=amount_col,
        hole=0.4,
        title="支出項目別　平均支出構成（月平均）",
        labels={category_col:"支出項目", amount_col:"平均支出(円)"},
        color_discrete_sequence=px.colors.qualitative.Set3
    )
    fig.update_traces(
        hovertemplate=(
            "項目:%{label}<br>"
            "平均支出:%{value:,.0f}円<br>"
            "割合:%{percent:.1%}<extra></extra>"
        ),
        texttemplate="%{label}<br>%{percent:.1%}",
        textposition="inside"
    )
    fig.update_layout(hoverlabel=dict(font_size=16))
    st.plotly_chart(fig, use_container_width=True)
    # -- Display donut chart and capture clicks
    st.write("クリックすると、下に中分類項目の詳細が表示されます。")
    # Dropdown to pick a main category for drill-down
    selected_category = st.selectbox(
        label="中分類項目",
        options=[""] + avg_by_category[category_col].tolist()
    )


    # if a slice is clicked, drill down to sub category--
    if selected_category:
        st.markdown(f"#### {selected_category} 内訳（中分類項目）")
        sub_df = sub_filtered_df[sub_filtered_df[category_col] == selected_category]
        sub_avg = (
            sub_df.groupby(sub_category_col, as_index=False)[amount_col]
                .mean()
                .sort_values(amount_col, ascending=True)
        )
        total_amount = sub_avg[amount_col].sum()
        sub_avg["percentage"] = sub_avg[amount_col]/total_amount * 100

        fig_bar = px.bar(
            sub_avg,
            x=amount_col,
            y=sub_category_col,
            orientation="h",
            title=f"{selected_category}内　中分類項目別　平均支出",
            labels={sub_category_col: "中分類項目", amount_col:"平均支出(円）"},
            custom_data=["percentage"]
        )
        fig_bar.update_traces(
            hovertemplate=("中分類項目別: %{y}<br>"
                            "平均支出:%{x:,.0f}円<br>"
                            "構成比:%{customdata[0]:.1f}%<extra></extra>"
        ))
        fig_bar.update_layout(hoverlabel=dict(font_size=16))
        st.plotly_chart(fig_bar, use_container_width=True)

    




