<?php

// credentials.php holds my username and password for KO. You should create it and put in the following variables:
require('credentials.php');
// $ko_db_host = ...;
// $ko_db_name = ...;
// $ko_db_user = ...;
// $ko_db_password = ...;

// CREATE TABLE kocrash (id INTEGER AUTO_INCREMENT, report_type VARCHAR(16), app VARCHAR(255), version VARCHAR(255), crash_date TIMESTAMP, ip VARCHAR(39), report TEXT, PRIMARY KEY(id));

function ko_get_field($field) {
	if ((string)$_POST[$field])
		return $_POST[$field];
	echo "Invalid $field field.";
	die;
}

$report_type = ko_get_field('type');
$app = ko_get_field('app');
$version = ko_get_field('version');
$crash_date = ko_get_field('date');
$ip = $_SERVER['REMOTE_ADDR'];
$report = ko_get_field('blob');

$db = new PDO("mysql:host=$ko_db_host;dbname=$ko_db_name", $ko_db_user, $ko_db_password);
$db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_SILENT);
$stmt = $db->("INSERT INTO kocrash (report_type, app, version, crash_date, ip, report) VALUES (?, ?, ?, ?, ?, ?)", );
$stmt->execute(array($report_type, $app, $version, $crash_date, $ip, $report));

?>
