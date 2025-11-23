$(document).ready(function () {
    mouseEvent();
    $('li[class^="type-"]').on('click', function (e) {
        e.preventDefault();
        //var id = $(this).data("pos");
        var title = $(this).find('span').html();
        //$("#description .modal-title").html(title);

        $("#description .modal-body").html("");
        var path = window.location.pathname;
        var directory = path.substring(path.indexOf('/'), path.lastIndexOf('/'));

        var url = decodeURI(directory + "/Pages/" + title + ".html");
        $.ajax({
            url: url,
            type: 'GET',
            dataType: 'html',
            crossDomain: true,
            success: function (data, status) {
                $("#description .modal-body").html(data);
            },
            error: function (XMLHttpRequest, textStatus, errorThrown) {
                //alert("Status: " + textStatus + " |  Error: " + errorThrown); 
            },
            complete: function (jqXHR, status) {
                //alert("Status: " + textStatus + " |  Error: " + errorThrown);
                if (status == "error") {
                    $("#description .modal-body").html('<div style="text-align:center; margin-top:50px;"><img src="Images/ComingSoon.png"/></div>');
                }
            }
        });
        //$('#description').modal({ backdrop: 'static' });
        $('#description').modal();
    });
});

function mouseEvent() {
    $('li[class^="type-"]').mouseover(function () {
        var currentClass = $(this).attr('class').split(' ')[0];
        if (currentClass != 'empty') {
            $('.main > li').addClass('deactivate');
            $('.' + currentClass).removeClass('deactivate');
        }
    });

    $('li[class^="cat-"]').mouseover(function () {
        var currentClass = $(this).attr('class').split(' ')[0];
        $('.main > li').addClass('deactivate');
        $('.' + currentClass).removeClass('deactivate');
    });

    $('.main > li').mouseout(function () {
        var currentClass = $(this).attr('class').split(' ')[0];
        $('.main > li').removeClass('deactivate');
    });
}