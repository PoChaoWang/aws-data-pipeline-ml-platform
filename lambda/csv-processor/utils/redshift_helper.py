import boto3

redshift_data = boto3.client('redshift-data')

def execute_redshift_query(cluster_id, database, db_user, sql_query):
    """Executes a query on a Redshift cluster using the Data API."""
    try:
        response = redshift_data.execute_statement(
            ClusterIdentifier=cluster_id,
            Database=database,
            DbUser=db_user,
            Sql=sql_query
        )
        return response
    except Exception as e:
        print(f"Error executing Redshift query: {e}")
        raise e