<?php
/**
 * Session Test Script for Memcache
 * ทดสอบการทำงานของ session กับ Memcache
 */

// เริ่มต้น session
session_start();

// ตรวจสอบการตั้งค่า session
echo "<h2>Session Configuration</h2>";
echo "<table border='1' cellpadding='5'>";
echo "<tr><td><b>Session Save Handler</b></td><td>" . ini_get('session.save_handler') . "</td></tr>";
echo "<tr><td><b>Session Save Path</b></td><td>" . ini_get('session.save_path') . "</td></tr>";
echo "<tr><td><b>Session ID</b></td><td>" . session_id() . "</td></tr>";
echo "<tr><td><b>Session Name</b></td><td>" . session_name() . "</td></tr>";
echo "</table>";

// ตรวจสอบการเชื่อมต่อ Memcache
echo "<h2>Memcache Connection Test</h2>";
if (class_exists('Memcache')) {
    echo "<p style='color: green;'>✅ Memcache extension is loaded</p>";

    $m = new Memcache();
    $m->addServer('memcached', 11211);

    // ทดสอบการเชื่อมต่อ
    $version = $m->getVersion();
    if ($version) {
        echo "<p style='color: green;'>✅ Connected to Memcache server</p>";
        echo "<pre>Server version: " . $version . "</pre>";
    } else {
        echo "<p style='color: red;'>❌ Cannot connect to Memcache server</p>";
    }

    // ทดสอบ set/get
    $testKey = 'test_key_' . time();
    $testValue = 'Hello Memcache! Time: ' . date('Y-m-d H:i:s');

    if ($m->set($testKey, $testValue, 0, 60)) {
        echo "<p style='color: green;'>✅ Successfully stored test data</p>";
        $retrieved = $m->get($testKey);
        if ($retrieved === $testValue) {
            echo "<p style='color: green;'>✅ Successfully retrieved test data: <b>$retrieved</b></p>";
        } else {
            echo "<p style='color: red;'>❌ Data mismatch</p>";
        }
    } else {
        echo "<p style='color: red;'>❌ Cannot store test data</p>";
    }
} else {
    echo "<p style='color: red;'>❌ Memcache extension is NOT loaded</p>";
}

// ทดสอบการใช้งาน session
echo "<h2>Session Test</h2>";

// เพิ่มข้อมูลลง session
if (!isset($_SESSION['visit_count'])) {
    $_SESSION['visit_count'] = 1;
    $_SESSION['first_visit'] = date('Y-m-d H:i:s');
    echo "<p style='color: blue;'>🆕 New session created</p>";
} else {
    $_SESSION['visit_count']++;
    echo "<p style='color: blue;'>🔄 Existing session found</p>";
}

$_SESSION['last_visit'] = date('Y-m-d H:i:s');
$_SESSION['random_data'] = 'Random: ' . rand(1000, 9999);

// แสดงข้อมูล session
echo "<table border='1' cellpadding='5'>";
echo "<tr><th>Session Key</th><th>Value</th></tr>";
foreach ($_SESSION as $key => $value) {
    echo "<tr><td><b>$key</b></td><td>$value</td></tr>";
}
echo "</table>";

// ทดสอบการ refresh
echo "<h2>Test Instructions</h2>";
echo "<ol>";
echo "<li>กด <b>Refresh (F5)</b> หน้านี้หลายๆ รอบ</li>";
echo "<li>ตรวจสอบว่า <b>visit_count</b> เพิ่มขึ้นทุกครั้ง</li>";
echo "<li>ตรวจสอบว่า <b>Session ID</b> ยังคงเหมือนเดิม</li>";
echo "<li>ถ้า session ทำงานถูกต้อง แสดงว่า Memcache ทำงานได้</li>";
echo "</ol>";

echo "<p><a href='?action=destroy' style='color: red; font-weight: bold;'>🗑️ Destroy Session</a></p>";

// ลบ session ถ้ามีการร้องขอ
if (isset($_GET['action']) && $_GET['action'] == 'destroy') {
    session_destroy();
    echo "<p style='color: red;'>✅ Session destroyed! <a href='test_session.php'>Reload page</a></p>";
}

// แสดง PHP Info
echo "<h2>PHP Session Info</h2>";
echo "<pre>";
echo "PHP Version: " . phpversion() . "\n";
echo "Loaded Extensions: " . (extension_loaded('memcache') ? 'memcache ✅' : 'memcache ❌') . "\n";
echo "</pre>";

echo "<hr>";
echo "<p><small>Generated at: " . date('Y-m-d H:i:s') . "</small></p>";
?>
