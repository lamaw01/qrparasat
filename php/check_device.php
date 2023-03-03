<?php
require 'db_connect.php';
header('Content-Type: application/json; charset=utf-8');

// make input json
$inputJSON = file_get_contents('php://input');
$input = json_decode($inputJSON, TRUE);

// if not put device_id die
if(isset($_POST['device_id'])){
    die('missing headers');
}else{
    $device_id = $input['device_id'];

    // last output
    $result = array('authorized'=>null, 'success'=>null);

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
            $result['success'] = true;
        }else{
            $result['authorized'] = false;
            $result['success'] = true;
        }
        echo json_encode($result);
    } catch (PDOException $e) {
        $result['authorized'] = $e->getMessage();
        $result['success'] = false;
        echo json_encode($result);
    } finally{
        // Closing the connection.
        $conn = null;
    }
}
?>