<?php
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
    $already_logged = 'ALREADY IN';

    // last output
    $result = array('name'=>null, 'log_type'=>null, 'success'=>null);

    // query get employee last log
    $sql_last_log = 'SELECT tbl_employee.employee_id, tbl_employee.name, tbl_logs.log_type, tbl_logs.time_stamp
    FROM tbl_employee 
    LEFT JOIN tbl_logs ON tbl_employee.employee_id = tbl_logs.employee_id
    WHERE tbl_logs.employee_id = :employee_id AND tbl_employee.active = 1
    ORDER BY tbl_logs.time_stamp DESC LIMIT 1';

    // query check if employee has data
    $sql_check_employee_exist = 'SELECT * FROM tbl_employee 
    WHERE employee_id = :employee_id AND active = 1';

    // query insert new log
    $sql_insert_log = 'INSERT INTO tbl_logs(employee_id, log_type)
    VALUES (:employee_id,:log_type)';

    try {
        // get employee last log
        $get_employee_last_log = $conn->prepare($sql_last_log);
        $get_employee_last_log->bindParam(':employee_id', $employee_id, PDO::PARAM_STR);
        $get_employee_last_log->execute();
        $result_last_log = $get_employee_last_log->fetch(PDO::FETCH_ASSOC);
        // insert new log
        if($result_last_log){
            $employee_name = $result_last_log['name'];
            $log_type = $result_last_log['log_type'];
            $time_stamp = $result_last_log['time_stamp'];
            $current_time_stamp = date('Y-m-d H:i:s');
            $time_difference = strtotime($current_time_stamp) - strtotime($time_stamp);
            // if time difference not yet 60 secods, do not log. 14400 = 4 hours
            if($time_difference <= 60 && $log_type == 'IN'){
                $result['log_type'] = $already_logged;
            }else{
                $insert_in_employee = $conn->prepare($sql_insert_log);
                $insert_in_employee->bindParam(':employee_id', $employee_id, PDO::PARAM_STR);
                // in or out
                if($log_type == 'OUT'){
                    $insert_in_employee->bindParam(':log_type', $log_in, PDO::PARAM_STR);
                    $result['log_type'] = $log_in;
                }else{
                    $insert_in_employee->bindParam(':log_type', $log_out, PDO::PARAM_STR);
                    $result['log_type'] = $log_out;
                }
                $insert_in_employee->execute();
            }
            $result['name'] = $employee_name;
            $result['success'] = true;
            echo json_encode($result);
        }
        // insert new log if user has no logs yet
        else{
            //check if employee id exist
            $get_employee_exist = $conn->prepare($sql_check_employee_exist);
            $get_employee_exist->bindParam(':employee_id', $employee_id, PDO::PARAM_STR);
            $get_employee_exist->execute();
            $result_employee_exist = $get_employee_exist->fetch(PDO::FETCH_ASSOC);
            // if exist insert log
            if($result_employee_exist){
                $employee_name_new = $result_employee_exist['name'];
                $insert_in_employee = $conn->prepare($sql_insert_log);
                $insert_in_employee->bindParam(':employee_id', $employee_id, PDO::PARAM_STR);
                $insert_in_employee->bindParam(':log_type', $log_in, PDO::PARAM_STR);
                $insert_in_employee->execute();
                // $result = ['data' => $conn->lastInsertId()];
                $result['name'] = $employee_name_new;
                $result['log_type'] = $log_in;
                $result['success'] = true;
                echo json_encode($result);
            }else{
                $result['name'] = 'Id doesnt exist or non-active';
                $result['log_type'] = 'ERROR';
                $result['success'] = true;
                echo json_encode($result);
            }
        }
    } catch (PDOException $e) {
        $result['name'] = $e->getMessage();
        $result['log_type'] = 'PDOException Error';
        $result['success'] = false;
        echo json_encode($result);
    } finally{
        // Closing the connection.
        $conn = null;
    }
}
?>