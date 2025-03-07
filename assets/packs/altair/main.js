import vegaEmbed from "vega-embed";

// The theme copied from kino_vega_lite [1].
//
// [1]: https://github.com/livebook-dev/kino_vega_lite/blob/v0.1.13/assets/vega_lite/main.js

const color = {
  blue300: "#b2c1ff",
  blue400: "#8ba2ff",
  blue500: "#6583ff",
  blue600: "#3e64ff",
  blue700: "#2d4cdb",
  blue800: "#1f37b7",
  blue900: "#132593",
  yellow600: "#ffa83f",
  yellow800: "#b7641f",
  red500: "#e2474d",
  red700: "#bc1227",
  green500: "#4aa148",
  green700: "#137518",
  gray200: "#e1e8f0",
  gray600: "#445668",
  gray800: "#1c2a3a",
  gray900: "#0d1829",
};

const primaryColors = [
  color.blue500,
  color.yellow600,
  color.red500,
  color.green500,
  color.blue700,
  color.yellow800,
  color.red700,
  color.green700,
];

const blues = [
  color.blue300,
  color.blue400,
  color.blue500,
  color.blue600,
  color.blue700,
  color.blue800,
  color.blue900,
];

const markColor = color.blue500;

const livebookTheme = {
  background: "#fff",

  title: {
    anchor: "center",
    fontSize: 18,
    fontWeight: 400,
    color: color.gray600,
    fontFamily: "Inter",
    font: "Inter",
  },

  arc: { fill: markColor },
  area: { fill: markColor },
  line: { stroke: markColor, strokeWidth: 2 },
  path: { stroke: markColor },
  rect: { fill: markColor },
  shape: { stroke: markColor },
  symbol: { fill: markColor, strokeWidth: 1.5, size: 50 },
  bar: { fill: markColor, stroke: null },
  circle: { fill: markColor },
  tick: { fill: markColor },
  rule: { color: color.gray900, size: 2 },
  text: { color: color.gray900 },

  axisBand: {
    grid: false,
    tickExtra: true,
  },

  legend: {
    titleFontWeight: 400,
    titleFontColor: color.gray600,
    titleFontSize: 13,
    titlePadding: 10,
    labelBaseline: "middle",
    labelFontSize: 12,
    symbolSize: 100,
    symbolType: "circle",
  },

  axisY: {
    gridColor: color.gray200,
    titleFontSize: 12,
    titlePadding: 10,
    labelFontSize: 12,
    labelPadding: 8,
    titleColor: color.gray800,
    titleFontWeight: 400,
  },

  axisX: {
    domain: true,
    domainColor: color.gray200,
    titlePadding: 10,
    titleColor: color.gray800,
    titleFontWeight: 400,
  },

  range: {
    category: primaryColors,
    ramp: blues,
    ordinal: blues,
  },
};

export function init(ctx, spec) {
  ctx.importCSS(
    "https://fonts.googleapis.com/css2?family=Inter:wght@400;500&display=swap"
  );

  const options = {
    actions: { export: true, source: true, compiled: false, editor: true },
    config: livebookTheme,
  };

  vegaEmbed(ctx.root, JSON.parse(spec), options)
    .catch((error) => {
      const message = `Failed to render the given Vega-Lite specification, got the following error:\n\n    ${error.message}\n\nMake sure to check for typos.`;

      ctx.root.innerHTML = `
        <div style="color: #FF3E38; white-space: pre-wrap;">${message}</div>
      `;
    });
}
