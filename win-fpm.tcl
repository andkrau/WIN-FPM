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
if { ![info exists basePort] || ![info exists poolSize] || ![info exists phpDir] || ![info exists fcgiChildren] || ![info exists listenHost]} {
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

puts "Creating pool of $poolSize PHP processes"

set pool [tpool::create -minworkers $poolSize -maxworkers $poolSize -initcmd {
    proc spinUp {port path host} {
        exec -- $path -b ${host}:${port}
        puts "Restarting PHP process listening on port $port"
        spinUp $port $path $host
    }
}]

set i 0
while {$i < $poolSize} {
    puts "starting PHP process listening on port [expr {$basePort + $i}]"
    lappend work [tpool::post -nowait $pool [list spinUp [expr {$basePort + $i}] $phpDir $listenHost]]
    incr i
}

puts "PHP FastCGI Pool Created!"

foreach id $work {
    tpool::wait $pool $id
    set response [tpool::get $pool $id]
    puts "ERROR: $response"
    puts "Killing any stray PHP processes"
    catch {exec -ignorestderr -- taskkill /F /IM php-cgi.exe 2> nul}
    exit
}
