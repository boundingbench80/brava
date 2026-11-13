/* Registra el pedido en Supabase antes de confirmar el envío. */
(() => {
  const cfg = window.BRAVA_SUPABASE || {};
  const enviar = async payload => {
    if (!cfg.url || !cfg.anonKey) throw new Error('La conexión con Supabase no está configurada.');
    for (let attempt = 0; attempt < 2; attempt++) {
      try {
        const r = await fetch(`${cfg.url.replace(/\/$/, '')}/rest/v1/rpc/registrar_pedido`, {
          method: 'POST', headers: { apikey: cfg.anonKey, Authorization: `Bearer ${cfg.anonKey}`, 'Content-Type': 'application/json' },
          body: JSON.stringify({ p: payload })
        });
        if (r.ok) {
          const result = await r.json();
          if (!result || result.codigo !== payload.codigo) throw new Error('Supabase no confirmó el código del pedido.');
          return result;
        }
        const detail = await r.text().catch(() => '');
        const error = new Error(`Supabase rechazó el pedido (${r.status})${detail ? `: ${detail}` : ''}`);
        if (r.status >= 400 && r.status < 500) throw error;
        if (attempt === 1) throw error;
      } catch (error) {
        if (attempt === 1 || /^Supabase rechazó el pedido \(4/.test(error.message)) throw error;
      }
    }
  };
  window.registrarPedido = enviar;
})();
