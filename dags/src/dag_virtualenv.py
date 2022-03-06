from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonVirtualenvOperator
from airflow.utils.dates import days_ago


feed_sources = {
    'example': {'link': 'https://www.example.com/rss/'},
}


default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 3,
    'retry_delay': timedelta(minutes=1),
    'start_date': days_ago(1)
}

dag = DAG(
    'feed_dag', 
    default_args=default_args, 
    schedule='0 */2 * * *',
    catchup=False
)



def rssScraper(feed_name, feed_link):
    from feed_service import rssScraper

    return rssScraper(feed_name=feed_name, feed_link=feed_link)

def feedBrainVector(name):
    from feed_service import feedBrainVector

    return feedBrainVector(name=name)  



    

for feed_name, data in feed_sources.items():

    scrape_task = PythonVirtualenvOperator(
        task_id='feed_{}'.format(feed_name),
        python_callable=rssScraper,
        op_kwargs={'feed_name': feed_name, 'feed_link': data['link']},
        requirements=["feedparser","pymongo","redis"],
        dag=dag)

    push_task = PythonVirtualenvOperator(
        task_id='feed_vector_task_{}'.format(feed_name),
        python_callable=feedBrainVector,
        op_kwargs={'name': feed_name},
        requirements=["feedparser","pymongo","redis"],
        dag=dag)

    scrape_task >> push_task

    scrape_task 