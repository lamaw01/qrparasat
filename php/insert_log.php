<?php
require 'db_connect.php';
header('Content-Type: application/json; charset=utf-8');

// make input json
$inputJSON = file_get_contents('php://input');
$input = json_decode($inputJSON, TRUE);

// data array
$result = array('name'=>null, 'log_type'=>null);

// if not put employee_id die
if($_SERVER['REQUEST_METHOD'] == 'POST' && array_key_exists('employee_id', $input)){
    $employee_id = $input['employee_id'];
    $address = $input['address'];
    $latlng = $input['latlng'];
    $device_id = $input['device_id'];
    $branch_id = $input['branch_id'];
    $log_in = 'IN';
    $log_out = 'OUT';
    $already_logged = 'ALREADY IN';
    $current_time_stamp = date('Y-m-d H:i:s');

    // query get employee last log
    $sql_last_log = 'SELECT tbl_employee.employee_id, tbl_employee.name, tbl_logs.log_type, tbl_logs.time_stamp
    FROM tbl_employee 
    LEFT JOIN tbl_logs ON tbl_employee.employee_id = tbl_logs.employee_id
    WHERE tbl_logs.employee_id = :employee_id AND tbl_employee.active = 1
    ORDER BY tbl_logs.time_stamp DESC LIMIT 1';

    // query check if employee has data
    $sql_check_employee_exist = 'SELECT * FROM tbl_employee 
    WHERE employee_id = :employee_id AND active = 1';

    // query check employee branch
    $sql_check_employee_branch = 'SELECT * FROM tbl_employee_branch 
    WHERE employee_id = :employee_id AND branch_id = :branch_id';

    // query insert new log
    $sql_insert_log = 'INSERT INTO tbl_logs(employee_id, log_type, address, latlng, device_id)
    VALUES (:employee_id,:log_type,:address,:latlng,:device_id)';
    try {
        //check if employee id exist
        $get_valid_id= $conn->prepare($sql_check_employee_exist);
        $get_valid_id->bindParam(':employee_id', $employee_id, PDO::PARAM_STR);
        $get_valid_id->execute();
        $result_valid_id = $get_valid_id->fetch(PDO::FETCH_ASSOC);
        // check if user exist
        if(!$result_valid_id){
            echo json_encode(array('success'=>false,'message'=>'Invalid id','data'=>$result));
            return;
        }
        // check if user exist in the branch
        $get_employee_branch = $conn->prepare($sql_check_employee_branch);
        $get_employee_branch->bindParam(':employee_id', $employee_id, PDO::PARAM_STR);
        $get_employee_branch->bindParam(':branch_id', $branch_id, PDO::PARAM_STR);
        $get_employee_branch->execute();
        $result_employee_branch = $get_employee_branch->fetch(PDO::FETCH_ASSOC);
        if($result_employee_branch){
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
                $time_difference = strtotime($current_time_stamp) - strtotime($time_stamp);
                // if time difference not yet 15 secods, do not log. 14400 = 4 hours
                if($time_difference <= 15 && $log_type == 'IN'){
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
                    $insert_in_employee->bindParam(':address', $address, PDO::PARAM_STR);
                    $insert_in_employee->bindParam(':latlng', $latlng, PDO::PARAM_STR);
                    $insert_in_employee->bindParam(':device_id', $device_id, PDO::PARAM_STR);
                    $insert_in_employee->execute();
                }
                $result['name'] = $employee_name;
                echo json_encode(array('success'=>true,'message'=>'Ok','data'=>$result));
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
                    $insert_in_employee->bindParam(':address', $address, PDO::PARAM_STR);
                    $insert_in_employee->bindParam(':latlng', $latlng, PDO::PARAM_STR);
                    $insert_in_employee->bindParam(':device_id', $device_id, PDO::PARAM_STR);
                    $insert_in_employee->execute();
                    // $result = ['data' => $conn->lastInsertId()];
                    $result['name'] = $employee_name_new;
                    $result['log_type'] = $log_in;
                    echo json_encode(array('success'=>true,'message'=>'Ok','data'=>$result));
                }else{
                    echo json_encode(array('success'=>false,'message'=>'User doesnt exist','data'=>$result));
                }
            }
        }else{
            echo json_encode(array('success'=>false,'message'=>'User not in branch','data'=>$result));
        }
    } catch (PDOException $e) {
        echo json_encode(array('success'=>false,'message'=>$e->getMessage(),'data'=>$result));
    } finally{
        // Closing the connection.
        $conn = null;
    }
}else{
    echo json_encode(array('success'=>false,'message'=>'Error input','data'=>$result));
    die();
}
?>