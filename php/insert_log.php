<?php

// connect to the database and select the result
require 'db_connect.php';
header('Content-Type: application/json; charset=utf-8');

// make input json
$inputJSON = file_get_contents('php://input');
$input = json_decode($inputJSON, TRUE);

// if not put employee_id die
if(isset($_POST['employee_id'])){
    die('missing headers');
}else{
    $employee_id = $input['employee_id'];
    $log_in = 'IN';
    $log_out = 'OUT';

    // last output
    $result = array('success'=>null);

    // query get employee last log
    $sql_last_log = 'SELECT tbl_employee.employee_id, tbl_employee.name, tbl_logs.log_type
    FROM tbl_employee 
    LEFT JOIN tbl_logs ON tbl_employee.employee_id = tbl_logs.employee_id
    WHERE tbl_logs.employee_id = :employee_id 
    ORDER BY tbl_logs.time_stamp DESC LIMIT 1';

    // query check if employee has data
    $sql_check_employee_exist = 'SELECT * FROM tbl_employee 
    WHERE employee_id = :employee_id';

    // query insert new log
    $sql_insert_log = 'INSERT INTO tbl_logs(employee_id, log_type)
    VALUES (:employee_id,:log_type)';

    try {
        // get employee last log
        $get_employee_last_log = $conn->prepare($sql_last_log);
        $get_employee_last_log->bindParam(':employee_id', $employee_id, PDO::PARAM_INT);
        $get_employee_last_log->execute();
        $result_last_log = $get_employee_last_log->fetch(PDO::FETCH_ASSOC);
        // insert new log
        if($result_last_log){
            $employee_name = $result_last_log['name'];
            // $myObj->employee_id = $result_last_log['employee_id'];
            // $myObj->name = $result_last_log['name'];
            // $myObj->log_type = $result_last_log['log_type'];
            // $myJSON = json_encode($myObj);
            // echo($myJSON);
            $insert_in_employee = $conn->prepare($sql_insert_log);
            $insert_in_employee->bindParam(':employee_id', $employee_id, PDO::PARAM_INT);
            // in or out
            if($result_last_log['log_type'] == 'OUT'){
                $insert_in_employee->bindParam(':log_type', $log_in, PDO::PARAM_STR);
            }else{
                $insert_in_employee->bindParam(':log_type', $log_out, PDO::PARAM_STR);
            }
            $insert_in_employee->execute();
            $result = ['data' => $employee_name];
            $result['success'] = true;
            echo json_encode($result);
        }
        // insert new log if user has no logs yet
        else{
            // check if employee id exist
            $get_employee_exist = $conn->prepare($sql_check_employee_exist);
            $get_employee_exist->bindParam(':employee_id', $employee_id, PDO::PARAM_INT);
            $get_employee_exist->execute();
            $result_employee_exist = $get_employee_exist->fetch(PDO::FETCH_ASSOC);
            // if exist insert log
            if($result_employee_exist){
                $insert_in_employee = $conn->prepare($sql_insert_log);
                $insert_in_employee->bindParam(':employee_id', $employee_id, PDO::PARAM_INT);
                $insert_in_employee->bindParam(':log_type', $log_in, PDO::PARAM_STR);
                $insert_in_employee->execute();
                // $result = ['data' => $conn->lastInsertId()];
                $result = ['data' => $employee_name];
                $result['success'] = true;
                echo json_encode($result);
            }else{
                $result = ['data' => 'employee id doest exist'];
                $result['success'] = false;
                echo json_encode($result);
            }
        }
    } catch (PDOException $e) {
        $result = ['data' => "PDOException Error: <br>".$e->getMessage()];
        $result['success'] = false;
        echo json_encode($result);
    } catch (Exception $e) {
        $result  = ['data' =>  "Exception Error: <br>".$e->getMessage()];
        $result['success'] = false;
        echo json_encode($result);
    }finally{
        // Closing the connection.
        $conn = null;
    }
    }
?>