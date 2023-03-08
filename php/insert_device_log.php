<?php
require 'db_connect.php';
header('Content-Type: application/json; charset=utf-8');

// make input json
$inputJSON = file_get_contents('php://input');
$input = json_decode($inputJSON, TRUE);


if($_SERVER['REQUEST_METHOD'] == 'POST' && array_key_exists('device_id', $input)){
    $device_id = $input['device_id'];
    $log_time = $input['log_time'];

    // query insert new device logs
    $sql_insert_device_log = 'INSERT INTO tbl_device_logs(device_id, log_time)
    VALUES (:device_id,:log_time)';

    try {
        $insert_device_log = $conn->prepare($sql_insert_device_log);
        $insert_device_log->bindParam(':device_id', $device_id, PDO::PARAM_STR);
        $insert_device_log->bindParam(':log_time', $log_time, PDO::PARAM_STR);
        $insert_device_log->execute();
        echo json_encode(array('success'=>true,'message'=>'Ok'));
    } catch (PDOException $e) {
        echo json_encode(array('success'=>false,'message'=>$e->getMessage()));
    } finally{
        // Closing the connection.
        $conn = null;
    }
}else{
    echo json_encode(array('success'=>false,'message'=>'Error input'));
    die();
}
?>