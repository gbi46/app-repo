from django.contrib import admin
from django.urls import path
from django.http import HttpResponse

def health(request):
    return HttpResponse("OK")

urlpatterns = [
    path('admin/', admin.site.urls),
    path('health/', health),   # простий endpoint для k8s livenessProbe
]
