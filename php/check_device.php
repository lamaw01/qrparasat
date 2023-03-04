<?php
require 'db_connect.php';
header('Content-Type: application/json; charset=utf-8');

// make input json
$inputJSON = file_get_contents('php://input');
$input = json_decode($inputJSON, TRUE);

// last output
$result = array('authorized'=>null);

// if not put device_id die
if($_SERVER['REQUEST_METHOD'] == 'POST' && array_key_exists('device_id', $input)){
    $device_id = $input['device_id'];

    // query check if device is authorized
    $sql_check_device = 'SELECT * FROM tbl_device
    WHERE device_id = :device_id AND active = 1';

    try {
        $get_device= $conn->prepare($sql_check_device);
        $get_device->bindParam(':device_id', $device_id, PDO::PARAM_STR);
        $get_device->execute();
        $result_get_device = $get_device->fetch(PDO::FETCH_ASSOC);
        if($result_get_device){
            $result['authorized'] = true;
        }else{
            $result['authorized'] = false;
        }
        echo json_encode(array('success'=>true,'message'=>'Ok','data'=>$result));
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