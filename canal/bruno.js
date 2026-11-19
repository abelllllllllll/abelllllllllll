function bearSVG(id) {
  return `
<svg viewBox="0 0 700 800" width="100%" height="100%" style="overflow:visible">
  <ellipse cx="350" cy="780" rx="230" ry="26" fill="rgba(34,48,90,.15)" id="${id}-shadow"/>
  <g id="${id}-body">
    <!-- cuerpo -->
    <ellipse cx="350" cy="590" rx="210" ry="190" fill="#FF8A3D"/>
    <ellipse cx="350" cy="620" rx="135" ry="130" fill="#FFE3C2"/>
    <!-- patas -->
    <ellipse cx="240" cy="755" rx="80" ry="45" fill="#E5641A"/>
    <ellipse cx="460" cy="755" rx="80" ry="45" fill="#E5641A"/>
    <!-- brazo izquierdo -->
    <ellipse cx="160" cy="580" rx="55" ry="95" fill="#FF8A3D" transform="rotate(20 160 580)"/>
    <!-- brazo que saluda -->
    <g id="${id}-arm">
      <ellipse cx="545" cy="470" rx="55" ry="100" fill="#FF8A3D"/>
    </g>
    <!-- cabeza -->
    <g id="${id}-head">
      <circle cx="190" cy="150" r="70" fill="#FF8A3D"/><circle cx="190" cy="150" r="38" fill="#FFB98A"/>
      <circle cx="510" cy="150" r="70" fill="#FF8A3D"/><circle cx="510" cy="150" r="38" fill="#FFB98A"/>
      <circle cx="350" cy="280" r="200" fill="#FF8A3D"/>
      <ellipse cx="350" cy="350" rx="105" ry="80" fill="#FFE3C2"/>
      <ellipse cx="350" cy="315" rx="36" ry="26" fill="#22305A"/>
      <path d="M350 340 Q350 375 315 380 M350 340 Q350 375 385 380" stroke="#22305A" stroke-width="10" fill="none" stroke-linecap="round"/>
      <g id="${id}-eyes">
        <ellipse cx="275" cy="240" rx="30" ry="38" fill="#3B2314"/>
        <ellipse cx="425" cy="240" rx="30" ry="38" fill="#3B2314"/>
        <circle cx="286" cy="226" r="11" fill="#fff"/><circle cx="436" cy="226" r="11" fill="#fff"/>
      </g>
      <ellipse cx="225" cy="320" rx="30" ry="18" fill="#FF9EB5" opacity=".75"/>
      <ellipse cx="475" cy="320" rx="30" ry="18" fill="#FF9EB5" opacity=".75"/>
    </g>
    <!-- bufanda -->
    <path d="M190 445 Q350 510 510 445 L515 500 Q350 565 185 500 Z" fill="#3FB37F"/>
    <path d="M420 490 L470 490 L480 620 L425 610 Z" fill="#2E9466"/>
  </g>
</svg>`;
}
