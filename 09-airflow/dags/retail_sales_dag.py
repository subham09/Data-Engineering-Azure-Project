"""
retail_sales_dag.py
Apache Airflow DAG for the Retail Sales Analytics Pipeline.

Fabric Item: Apache Airflow (Job Scheduler)
DP-700 Skill: Implement and Manage Analytics Solution
             > Configure Apache Airflow workspace settings
             > Orchestrate processes > Schedule triggers

This DAG orchestrates the full medallion pipeline using
Microsoft Fabric's managed Apache Airflow (powered by
Azure Data Factory Managed Airflow).

Setup in Fabric:
    1. Workspace Settings → Data Engineering → Apache Airflow
    2. Enable Airflow in the workspace
    3. Upload this DAG to the Airflow DAGs folder (OneLake or Git sync)
    4. Configure the 'fabric_connection' in Airflow Connections
       (Type: HTTP, Host: api.fabric.microsoft.com)
"""

from __future__ import annotations

import json
import logging
from datetime import datetime, timedelta

from airflow import DAG
from airflow.models import Variable
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import BranchPythonOperator, PythonOperator
from airflow.providers.http.operators.http import SimpleHttpOperator
from airflow.providers.http.sensors.http import HttpSensor
from airflow.utils.trigger_rule import TriggerRule

log = logging.getLogger(__name__)

# ── DAG-level defaults ────────────────────────────────────────────────────────

FABRIC_WORKSPACE_ID = Variable.get("fabric_workspace_id", default_var="YOUR_WORKSPACE_ID")
FABRIC_PIPELINE_ID  = Variable.get("fabric_pipeline_id",  default_var="YOUR_PIPELINE_ID")
LOAD_MODE           = Variable.get("load_mode",            default_var="incremental")

DEFAULT_ARGS = {
    "owner":            "data-engineering",
    "depends_on_past":  False,
    "start_date":       datetime(2024, 1, 1),
    "email_on_failure": True,
    "email_on_retry":   False,
    "retries":          2,
    "retry_delay":      timedelta(minutes=5),
    "execution_timeout": timedelta(hours=2),
}

# ── Helper functions ──────────────────────────────────────────────────────────

def determine_load_mode(**context) -> str:
    """
    Branch logic: run full load on Sundays, incremental on other days.
    Returns the task_id of the branch to follow.
    """
    exec_date = context["data_interval_start"]
    day_of_week = exec_date.weekday()   # 0=Monday, 6=Sunday
    if day_of_week == 6:
        log.info("Sunday detected — routing to full_load branch")
        return "set_full_load"
    log.info(f"Weekday {day_of_week} — routing to incremental_load branch")
    return "set_incremental_load"


def build_pipeline_run_body(load_mode: str, **context) -> dict:
    """Build the Fabric REST API request body for triggering a pipeline run."""
    run_id = context["run_id"]
    return {
        "parameters": {
            "LoadMode":    load_mode,
            "TriggerType": "airflow",
            "AirflowRunId": run_id,
        }
    }


def set_load_mode_variable(mode: str, **context) -> None:
    """Push the resolved load mode to XCom for downstream tasks."""
    context["task_instance"].xcom_push(key="load_mode", value=mode)
    log.info(f"Load mode set to: {mode}")


def check_pipeline_success(**context) -> None:
    """Parse the pipeline run status from the sensor response and fail if needed."""
    ti    = context["task_instance"]
    resp  = ti.xcom_pull(task_ids="poll_pipeline_status")
    if isinstance(resp, str):
        resp = json.loads(resp)
    status = resp.get("status", "Unknown")
    log.info(f"Pipeline run final status: {status}")
    if status not in ("Succeeded",):
        raise ValueError(f"Fabric pipeline ended with status: {status}")


# ── DAG definition ────────────────────────────────────────────────────────────

with DAG(
    dag_id="retail_sales_fabric_pipeline",
    description="Orchestrates the Retail Sales Medallion pipeline via Fabric REST API",
    default_args=DEFAULT_ARGS,
    schedule="0 6 * * *",       # Daily at 06:00 UTC
    catchup=False,
    max_active_runs=1,           # Prevent concurrent runs
    tags=["fabric", "dp700", "retail", "medallion"],
    doc_md="""
## Retail Sales Analytics — Airflow DAG

Triggers the Microsoft Fabric Data Pipeline `PL_Master_RetailSalesLoad` via REST API.

### Schedule
- **Incremental load**: Monday–Saturday at 06:00 UTC
- **Full reload**: Sunday at 06:00 UTC (reprocesses all history)

### Branching
The `determine_load_mode` task inspects the execution date and routes to
either `set_full_load` or `set_incremental_load`.

### Retry policy
Each task retries twice with a 5-minute gap before alerting.

### DP-700 relevance
Demonstrates Apache Airflow integration with Fabric, covering the
"Configure Apache Airflow workspace settings" and "Orchestrate processes"
exam objectives.
    """,
) as dag:

    # ── Start ─────────────────────────────────────────────
    start = EmptyOperator(task_id="start")

    # ── Determine load mode ────────────────────────────────
    branch = BranchPythonOperator(
        task_id="determine_load_mode",
        python_callable=determine_load_mode,
    )

    set_full = PythonOperator(
        task_id="set_full_load",
        python_callable=set_load_mode_variable,
        op_kwargs={"mode": "full"},
    )

    set_incremental = PythonOperator(
        task_id="set_incremental_load",
        python_callable=set_load_mode_variable,
        op_kwargs={"mode": "incremental"},
    )

    join_branch = EmptyOperator(
        task_id="join_branch",
        trigger_rule=TriggerRule.ONE_SUCCESS,
    )

    # ── Trigger Fabric pipeline via REST API ───────────────
    # POST /v1/workspaces/{workspaceId}/items/{itemId}/jobs/instances?jobType=Pipeline
    trigger_pipeline = SimpleHttpOperator(
        task_id="trigger_fabric_pipeline",
        http_conn_id="fabric_api",                     # Configure in Airflow > Connections
        method="POST",
        endpoint=f"v1/workspaces/{FABRIC_WORKSPACE_ID}/items/{FABRIC_PIPELINE_ID}/jobs/instances?jobType=Pipeline",
        headers={
            "Content-Type": "application/json",
            "Authorization": "Bearer {{ conn.fabric_api.password }}",
        },
        data=json.dumps({
            "executionData": {
                "parameters": {
                    "LoadMode":    "{{ task_instance.xcom_pull(task_ids='set_full_load', key='load_mode') or task_instance.xcom_pull(task_ids='set_incremental_load', key='load_mode') }}",
                    "TriggerType": "airflow",
                }
            }
        }),
        response_check=lambda resp: resp.status_code == 202,   # 202 = Accepted
        log_response=True,
    )

    # ── Poll until pipeline finishes ───────────────────────
    # GET /v1/workspaces/{workspaceId}/items/{itemId}/jobs/instances/{jobInstanceId}
    poll_pipeline = HttpSensor(
        task_id="poll_pipeline_status",
        http_conn_id="fabric_api",
        endpoint=(
            f"v1/workspaces/{FABRIC_WORKSPACE_ID}/items/{FABRIC_PIPELINE_ID}"
            "/jobs/instances/{{ task_instance.xcom_pull(task_ids='trigger_fabric_pipeline')['id'] }}"
        ),
        headers={"Authorization": "Bearer {{ conn.fabric_api.password }}"},
        response_check=lambda resp: resp.json().get("status") in ("Succeeded", "Failed", "Cancelled"),
        poke_interval=60,        # Check every 60 seconds
        timeout=7200,            # Give up after 2 hours
        mode="reschedule",       # Free up worker slot while waiting
    )

    # ── Validate success ───────────────────────────────────
    validate_success = PythonOperator(
        task_id="validate_pipeline_success",
        python_callable=check_pipeline_success,
    )

    # ── Notify on completion ───────────────────────────────
    notify_success = EmptyOperator(
        task_id="notify_success",
        # In production: swap for SlackOperator or EmailOperator
    )

    notify_failure = EmptyOperator(
        task_id="notify_failure",
        trigger_rule=TriggerRule.ONE_FAILED,
        # In production: swap for SlackOperator or PagerDuty integration
    )

    end = EmptyOperator(
        task_id="end",
        trigger_rule=TriggerRule.ONE_SUCCESS,
    )

    # ── Dependencies ───────────────────────────────────────
    start >> branch >> [set_full, set_incremental] >> join_branch
    join_branch >> trigger_pipeline >> poll_pipeline >> validate_success
    validate_success >> notify_success >> end
    validate_success >> notify_failure >> end
