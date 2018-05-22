# Implements a sort of pseudo PHP-FPM on Windows

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
if { ![info exists listenPort] || ![info exists threads] || ![info exists path] } {
    puts "Missing arguments!"
    exit
}

set basePort [expr {$listenPort + 1}]
set host 127.0.0.1

puts "Killing all other running PHP processes"

catch {exec -ignorestderr -- taskkill /F /IM php-cgi.exe 2> nul}

puts "Creating $threads worker processes"

set pool [tpool::create -minworkers $threads -maxworkers $threads -initcmd {
    proc spinUp {port path} {
        exec -- $path -b 127.0.0.1:${port}
        spinUp $port $path
    }
}]

set i 0
while {$i < $threads} {
    lappend work [tpool::post -nowait $pool [list spinUp [expr {$basePort + $i}] $path]]
    lappend portList [expr {$basePort + $i}]
    incr i
}

set freePorts $portList

#Based upon http://wiki.tcl.tk/12670

proc accept {sock addr p} {
    global host freePorts
    set port [lindex $freePorts 0]
    set freePorts [lrange $freePorts 1 end]
    set conn [socket -async $host $port]
    fconfigure $sock -translation binary -buffering none -blocking 0
    fconfigure $conn -translation binary -buffering none -blocking 0
    puts "Relaying request to worker listening on port $port"
    fileevent  $conn readable [list xfer $conn $sock]
    fileevent  $sock readable [list xfer $sock $conn]
    lappend freePorts $port
}

proc xfer {from to} {
    if {([eof $from] || [eof $to]) || ([catch {read $from} data] || [catch {puts -nonewline $to $data}])} {
        catch {close $from}
        catch {close $to}
    }
}

puts "Listening on port $listenPort for incoming requests"

set server [socket -server accept $listenPort]

foreach id $work {
    tpool::wait $pool $id
    set response [tpool::get $pool $id]
    puts "ERROR: $response"
    exit
}

tpool::release $pool

puts "Killing any stray PHP processes"
catch {exec -ignorestderr -- taskkill /F /IM php-cgi.exe 2> nul}
