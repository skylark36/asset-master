import { use } from 'echarts/core'
import { CanvasRenderer } from 'echarts/renderers'
import { PieChart, LineChart } from 'echarts/charts'
import {
  GridComponent,
  TooltipComponent,
  LegendComponent,
  TitleComponent,
  ToolboxComponent
} from 'echarts/components'
import VChart from 'vue-echarts'

export default defineNuxtPlugin((nuxtApp) => {
  use([
    CanvasRenderer,
    PieChart,
    LineChart,
    GridComponent,
    TooltipComponent,
    LegendComponent,
    TitleComponent,
    ToolboxComponent
  ])
  
  // Register the vue-echarts component globally
  nuxtApp.vueApp.component('VChart', VChart)
})
