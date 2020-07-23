# Implements a PHP FastCGI Pool Manager on Windows

package require Thread

if { $argc > 0 } {
    set i 0
    foreach arg $argv {
        set arg [string trimleft $arg -]
        incr i
        set $arg [lindex $argv $i]
    }
} else {
    puts "no command line arguments passed!"
    exit
}
if { ![info exists basePort] || ![info exists poolSize] || ![info exists phpDir] || ![info exists fcgiChildren] || ![info exists listenHost] || ![info exists errorLimit]} {
    puts "Missing arguments!"
    exit
}

set phpDir [string trimright $phpDir /]
if {[file exists ${phpDir}/php-cgi.exe]} {
    set phpDir ${phpDir}/php-cgi.exe
} else {
    puts "php-cgi.exe not found in ${phpDir}!"
    exit
}

puts "Killing all other running PHP processes"
catch {exec -ignorestderr -- taskkill /F /IM php-cgi.exe 2> nul}

puts "Disabling PHP Max Requests Limit"
catch {exec cmd /C "setx PHP_FCGI_MAX_REQUESTS 0"}

puts "Setting Number of PHP FastCGI Child Processes"
catch {exec cmd /C "setx PHP_FCGI_CHILDREN $fcgiChildren"}

set totalProcesses $poolSize
set totalChildren [expr $fcgiChildren * $poolSize]
if {$fcgiChildren > 0} {
    set totalProcesses [expr $totalChildren + $poolSize]
}

puts "Creating pool of $poolSize PHP parent processes with $totalChildren total child processes"

set pool [tpool::create -minworkers $poolSize -maxworkers $poolSize -initcmd {
    proc spinUp {port path host stop fail} {
        try {
            exec -- $path -b ${host}:${port}
        } on error {message} {
            if {$fail > $stop} {
                return $message
            } else {
                puts "PHP process ended with error: $message"
            }
            incr fail
        } finally {
            puts "Restarting PHP process listening on port $port"
            spinUp $port $path $host $stop $fail
        }
    }
}]

set i 0
while {$i < $poolSize} {
    puts "starting PHP process listening on port [expr {$basePort + $i}]"
    lappend work [tpool::post -nowait $pool [list spinUp [expr {$basePort + $i}] $phpDir $listenHost $errorLimit 0]]
    incr i
}

puts "$totalProcesses total PHP processes started"
puts "PHP FastCGI pool ready"

foreach id $work {
    tpool::wait $pool $id
    set response [tpool::get $pool $id]
    puts "ERROR LIMIT MET WITH MESSAGE: $response"
    puts "Killing any stray PHP processes"
    catch {exec -ignorestderr -- taskkill /F /IM php-cgi.exe 2> nul}
    exit
}
