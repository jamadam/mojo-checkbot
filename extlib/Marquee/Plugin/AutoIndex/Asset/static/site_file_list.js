$(document).ready(function() {
    $("tbody tr").one('click', function() {
        document.location = $(this).find('a').attr('href');
        return false;
    });
});
