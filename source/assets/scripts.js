function toggleTable(tableId, arrowId) {
    var table = document.getElementById(tableId);
    var arrow = document.getElementById(arrowId);
    if (table.style.display === "none") {
        table.style.display = "table";
        arrow.classList.add("rotated");
    } else {
        table.style.display = "none";
        arrow.classList.remove("rotated");
    }
    sortBaseScoreDescending(); // call sort function after showing/hiding table
}


function toggleAll() {
    var tables = document.getElementsByTagName("table");
    var arrows = document.getElementsByClassName("arrow");
    for (var i = 0; i < tables.length; i++) {
        if (tables[i].style.display === "none") {
            tables[i].style.display = "table";
            arrows[i].classList.add("rotated");
        } else {
            tables[i].style.display = "none";
            arrows[i].classList.remove("rotated");
        }
    }
}

function sortTable(table, columnIndex) {
    var rows, switching, i, x, y, shouldSwitch, dir, switchcount = 0;
    switching = true;
    dir = "asc";
    while (switching) {
        switching = false;
        rows = table.rows;
        for (i = 1; i < (rows.length - 1); i++) {
            shouldSwitch = false;
            x = rows[i].getElementsByTagName("TD")[columnIndex];
            y = rows[i + 1].getElementsByTagName("TD")[columnIndex];
            if (dir == "asc") {
                if (x.innerHTML.toLowerCase() > y.innerHTML.toLowerCase()) {
                    shouldSwitch = true;
                    break;
                }
            } else if (dir == "desc") {
                if (x.innerHTML.toLowerCase() < y.innerHTML.toLowerCase()) {
                    shouldSwitch = true;
                    break;
                }
            }
        }
        if (shouldSwitch) {
            rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
            switching = true;
            switchcount ++;
        } else {
            if (switchcount == 0 && dir == "asc") {
                dir = "desc";
                switching = true;
            }
        }
    }
}

function sortBaseScoreDescending() {
    var tables = document.getElementsByTagName("table");
    for (var i = 0; i < tables.length; i++) {
        var table = tables[i];
        var rows = table.rows;
        var arr = new Array();
        for (var j = 1; j < rows.length; j++) {
            arr.push(rows[j]);
        }
        arr.sort(function(a, b) {
            var aVal = parseFloat(a.cells[5].textContent || a.cells[5].innerText);
            var bVal = parseFloat(b.cells[5].textContent || b.cells[5].innerText);
            return bVal - aVal;
        });
        for (var k = 0; k < arr.length; k++) {
            table.appendChild(arr[k]);
        }
    }
}

sortBaseScoreDescending();


function onHeaderClick(tableId, columnIndex) {
    var table = document.getElementById(tableId);
    sortTable(table, columnIndex);
}

function collapseAll() {
    var tables = document.getElementsByTagName("table");
    var arrows = document.getElementsByClassName("arrow");
    for (var i = 0; i < tables.length; i++) {
        tables[i].style.display = "none";
        arrows[i].classList.remove("rotated");
    }
}

function expandAll() {
    var tables = document.getElementsByTagName("table");
    var arrows = document.getElementsByClassName("arrow");
    for (var i = 0; i < tables.length; i++) {
        tables[i].style.display = "table";
        arrows[i].classList.add("rotated");
    }
}

