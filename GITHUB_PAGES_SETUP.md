# Configuración de GitHub Pages

## Pasos para activar GitHub Pages (Manual)

1. **Ve a tu repositorio en GitHub:**
   - https://github.com/guidoo25/webui

2. **Accede a Settings:**
   - Click en la pestaña "Settings" 
   - Baja a la sección "Pages" en el menú izquierdo

3. **Configura la fuente de GitHub Pages:**
   - **Source:** Selecciona "Deploy from a branch"
   - **Branch:** Selecciona "main"
   - **Folder:** Selecciona "/build/web"
   - Click en "Save"

4. **Espera a que se despliegue:**
   - GitHub Pages compilará automáticamente en unos minutos
   - Recibirás un email de confirmación
   - Tu sitio estará disponible en: https://guidoo25.github.io/webui/

## URLs de acceso

- **Raíz del repositorio:** https://guidoo25.github.io/webui/
- **Index.html:** https://guidoo25.github.io/webui/index.html
- **Cualquier archivo en build/web:** https://guidoo25.github.io/webui/{archivo}

## Alternativa: GitHub Actions (Automático)

Si prefieres que se actualice automáticamente cuando hagas push, créa un archivo `.github/workflows/deploy.yml` (lo haremos si lo necesitas).

## Nota importante

El archivo `.nojekyll` ya está incluido en el repositorio. Esto previene que GitHub intente procesar los archivos como Jekyll.

## Troubleshooting

Si no ves la aplicación:
1. Verifica que GitHub Pages esté habilitado en Settings > Pages
2. Confirma que la rama sea "main" y la carpeta sea "/build/web"
3. Espera 5 minutos (puede tomar tiempo el primer deploy)
4. Limpia la caché del navegador (Ctrl+Shift+Delete en Chrome)
5. Verifica en el navegador que no haya errores de CORS
