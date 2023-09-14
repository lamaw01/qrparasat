<?php
require '../db_connect.php';
header('Content-Type: application/json; charset=utf-8');

// make input json
$inputJSON = file_get_contents('php://input');
$input = json_decode($inputJSON, TRUE);

// if not put device_id die
if($_SERVER['REQUEST_METHOD'] == 'GET'){

    // query check if device is authorized
    $sql_get_app_version = 'SELECT * FROM tbl_app_version
    WHERE id = 1';

    try {
        $get_app_version= $conn->prepare($sql_get_app_version);
        $get_app_version->execute();
        $result_get_app_version = $get_app_version->fetch(PDO::FETCH_ASSOC);
        echo json_encode($result_get_app_version);
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