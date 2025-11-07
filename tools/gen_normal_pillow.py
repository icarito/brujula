#!/usr/bin/env python3
"""
Genera un normal map (tangent-space) a partir de una textura de altura implícita en el albedo
usando Sobel, implementado con Python + Pillow (sin NumPy requerido).

Uso:
  python tools/gen_normal_pillow.py INPUT.png OUTPUT.png --strength 1.2 --blur 1 --invert-y

Notas:
- La fuerza escala los gradientes (nx, ny). Valores típicos: 0.6..1.5
- El blur suaviza ruido antes del cálculo (entero; píxeles). 0 = sin blur.
- --invert-y invierte el eje Y del normal (útil si tu import espera DirectX vs OpenGL).
"""
import argparse
import math
from PIL import Image, ImageFilter

SOBEL_X = [
    [-1, 0, 1],
    [-2, 0, 2],
    [-1, 0, 1],
]
SOBEL_Y = [
    [-1, -2, -1],
    [ 0,  0,  0],
    [ 1,  2,  1],
]

def clamp(v, lo, hi):
    return lo if v < lo else hi if v > hi else v

def to_height(img: Image.Image, blur_radius: int) -> list:
    # Gris (luma) en [0,1]
    g = img.convert('L')
    if blur_radius > 0:
        g = g.filter(ImageFilter.GaussianBlur(blur_radius))
    w, h = g.size
    # Cargar a lista de floats
    px = list(g.getdata())
    return [p / 255.0 for p in px], w, h

def sample(height, w, h, x, y):
    # Clamp de bordes
    sx = 0 if x < 0 else (w - 1 if x >= w else x)
    sy = 0 if y < 0 else (h - 1 if y >= h else y)
    return height[sy * w + sx]

def sobel(height, w, h, x, y):
    gx = 0.0
    gy = 0.0
    for j in range(-1, 2):
        for i in range(-1, 2):
            v = sample(height, w, h, x + i, y + j)
            gx += v * SOBEL_X[j+1][i+1]
            gy += v * SOBEL_Y[j+1][i+1]
    return gx, gy

def generate_normal(input_path: str, output_path: str, strength: float, blur_radius: int, invert_y: bool):
    src = Image.open(input_path)
    height, w, h = to_height(src, blur_radius)

    out = Image.new('RGBA', (w, h))
    out_px = out.load()

    for y in range(h):
        for x in range(w):
            gx, gy = sobel(height, w, h, x, y)
            nx = gx * strength
            ny = (-gy if invert_y else gy) * strength
            nz = 1.0
            # Normalizar
            vlen = math.sqrt(nx*nx + ny*ny + nz*nz)
            if vlen > 0.0:
                nx /= vlen
                ny /= vlen
                nz /= vlen
            # Remap a [0,255]
            r = int(clamp((nx * 0.5 + 0.5) * 255.0, 0, 255))
            g = int(clamp((ny * 0.5 + 0.5) * 255.0, 0, 255))
            b = int(clamp((nz * 0.5 + 0.5) * 255.0, 0, 255))
            out_px[x, y] = (r, g, b, 255)

    out.save(output_path)
    print(f"Normal map generado: {output_path} (strength={strength}, blur={blur_radius}, invert_y={invert_y})")

if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('input', help='Imagen de entrada (albedo/altura base)')
    ap.add_argument('output', help='Normal map de salida (PNG recomendado)')
    ap.add_argument('--strength', type=float, default=1.0)
    ap.add_argument('--blur', type=int, default=1)
    ap.add_argument('--invert-y', action='store_true')
    args = ap.parse_args()

    generate_normal(args.input, args.output, args.strength, args.blur, args.invert_y)
