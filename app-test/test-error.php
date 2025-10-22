<?php
// Test PHP Error Reporting

echo "=== PHP Error Test ===\n\n";

// 1. Parse Error (Syntax Error)
echo "1. Testing Parse Error:\n";
// eval('echo "Missing semicolon"'); // Uncomment to test

// 2. Notice Error
echo "\n2. Testing Notice Error:\n";
echo $undefined_variable;

// 3. Warning Error
echo "\n3. Testing Warning Error:\n";
include('nonexistent_file.php');

// 4. Fatal Error (Uncomment to test - will stop execution)
echo "\n4. Testing Fatal Error:\n";
// call_undefined_function();

// 5. Division by Zero Warning
echo "\n5. Testing Division by Zero:\n";
$result = 10 / 0;

// 6. Array Access Error
echo "\n6. Testing Array Access Notice:\n";
$arr = array('a' => 1);
echo $arr['nonexistent_key'];

echo "\n\n=== Test Complete ===\n";
?>
