<div id="root">
  <div className="app-shell">
    <aside className="sidebar">
      <div className="brand">
        <span className="brand-mark">
          <svg aria-hidden="true" className width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
            <path d="M20 4c-8.4.2-14 4.1-14 10.1 0 3.2 2.2 5.4 5.2 5.4C17.8 19.5 20 11.3 20 4Z" />
            <path d="M4 21c1.4-5.2 5.2-9 11.4-11.4" />
          </svg>
        </span>
        <span>
          好好吃饭
        </span>
      </div>
      <nav className="sidebar-nav" aria-label="主导航">
        <button className="nav-item active">
          <svg aria-hidden="true" className width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
            <path d="m3 11 9-8 9 8" />
            <path d="M5 10v10h14V10M9 20v-6h6v6" />
          </svg>
          今日菜单
        </button>
        <button className="nav-item">
          <svg aria-hidden="true" className width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
            <rect x="3" y="5" width="18" height="16" rx="2" />
            <path d="M16 3v4M8 3v4M3 10h18M8 14h.01M12 14h.01M16 14h.01M8 18h.01M12 18h.01" />
          </svg>
          每周计划
        </button>
        <button className="nav-item">
          <svg aria-hidden="true" className width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
            <path d="M4 20V10M10 20V4M16 20v-7M22 20H2" />
          </svg>
          营养分析
        </button>
        <button className="nav-item">
          <svg aria-hidden="true" className width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
            <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20V4H6.5A2.5 2.5 0 0 0 4 6.5v13Z" />
            <path d="M4 19.5A2.5 2.5 0 0 0 6.5 22H20v-5" />
          </svg>
          健康食谱
        </button>
      </nav>
      <div className="weekly-card">
        <div className="weekly-icon">
          <svg aria-hidden="true" className width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
            <path d="m12 3 1.2 3.8L17 8l-3.8 1.2L12 13l-1.2-3.8L7 8l3.8-1.2L12 3Z" />
            <path d="m19 14 .7 2.3L22 17l-2.3.7L19 20l-.7-2.3L16 17l2.3-.7L19 14Z" />
          </svg>
        </div>
        <strong>
          本周健康目标
        </strong>
        <p>
          均衡饮食已坚持 4 天
        </p>
        <div className="mini-progress">
          <span style={ width: '57%' }>
          </span>
        </div>
        <small>
          4 / 7 天
        </small>
      </div>
      <button className="profile">
        <span className="avatar">
          林
        </span>
        <span>
          <strong>
            林小满
          </strong>
          <small>
            轻盈生活计划
          </small>
        </span>
        <svg aria-hidden="true" className width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
          <path d="m9 18 6-6-6-6" />
        </svg>
      </button>
    </aside>
    <main className="main-content">
      <header className="topbar">
        <div>
          <p className="eyebrow">
            2025年9月19日 · 星期四
          </p>
          <h1>
            早上好，小满
          </h1>
          <p className="subtitle">
            认真吃好每一餐，就是对生活最温柔的照顾。
          </p>
        </div>
        <button className="icon-button notification" aria-label="查看通知">
          <svg aria-hidden="true" className width="21" height="21" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
            <path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9" />
            <path d="M10 21h4" />
          </svg>
          <span>
          </span>
        </button>
      </header>
      <section className="date-strip" aria-label="选择日期">
        <button className="date-arrow" aria-label="前一天">
          <svg aria-hidden="true" className width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
            <path d="m15 18-6-6 6-6" />
          </svg>
        </button>
        <div className="date-list">
          <button className="date-cell">
            <span>
              周一
            </span>
            <strong>
              16
            </strong>
          </button>
          <button className="date-cell">
            <span>
              周二
            </span>
            <strong>
              17
            </strong>
          </button>
          <button className="date-cell">
            <span>
              周三
            </span>
            <strong>
              18
            </strong>
          </button>
          <button className="date-cell selected">
            <span>
              周四
            </span>
            <strong>
              19
            </strong>
            <i>
            </i>
          </button>
          <button className="date-cell">
            <span>
              周五
            </span>
            <strong>
              20
            </strong>
          </button>
          <button className="date-cell">
            <span>
              周六
            </span>
            <strong>
              21
            </strong>
          </button>
          <button className="date-cell">
            <span>
              周日
            </span>
            <strong>
              22
            </strong>
          </button>
        </div>
        <button className="date-arrow" aria-label="后一天">
          <svg aria-hidden="true" className width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
            <path d="m9 18 6-6-6-6" />
          </svg>
        </button>
      </section>
      <div className="dashboard-grid">
        <section className="menu-section">
          <div className="section-heading">
            <div>
              <h2>
                今日菜单
              </h2>
              <p>
                根据你的目标与偏好精心搭配
              </p>
            </div>
            <button className="add-button">
              <svg aria-hidden="true" className width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                <path d="M12 5v14M5 12h14" />
              </svg>
              添加食物
            </button>
          </div>
          <div className="meal-list">
            <article className="meal-card completed">
              <div className="meal-image-wrap">
                <img alt="莓果酸奶燕麦杯" className="meal-image" src="https://images.unsplash.com/photo-1629793982045-5f847bd65a61?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=85&w=800&h=600" />
                <span className="meal-tag">
                  早餐
                </span>
              </div>
              <div className="meal-info">
                <div className="meal-meta">
                  <span>
                    <svg aria-hidden="true" className width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                      <circle cx="12" cy="12" r="9" />
                      <path d="M12 7v5l3 2" />
                    </svg>
                     08:00
                  </span>
                  <span>
                    <svg aria-hidden="true" className width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M12 22c4.4 0 7-3.2 7-7.3 0-3.2-2-6.4-5-9.7-.5 3-2 4.2-3 5.5-.7-2-1.8-3.7-3.4-5C6.4 9 5 11.5 5 15c0 4 2.7 7 7 7Z" />
                    </svg>
                     420 千卡
                  </span>
                </div>
                <h3>
                  莓果酸奶燕麦杯
                </h3>
                <p>
                  希腊酸奶、燕麦、蓝莓、草莓与坚果
                </p>
                <div className="meal-actions">
                  <button className="replace-button">
                    <svg aria-hidden="true" className width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M20 7v5h-5" />
                      <path d="M4 17v-5h5M18.3 9A7 7 0 0 0 6.4 6.4L4 9M5.7 15A7 7 0 0 0 17.6 17.6L20 15" />
                    </svg>
                    换一个
                  </button>
                  <button className="complete-button done">
                    <svg aria-hidden="true" className width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                      <path d="m5 12 4 4L19 6" />
                    </svg>
                    已完成
                  </button>
                </div>
              </div>
            </article>
            <article className="meal-card">
              <div className="meal-image-wrap">
                <img alt="香煎三文鱼藜麦碗" className="meal-image" src="https://images.unsplash.com/photo-1543352634-a1c51d9f1fa7?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=85&w=800&h=600" />
                <span className="meal-tag">
                  午餐
                </span>
              </div>
              <div className="meal-info">
                <div className="meal-meta">
                  <span>
                    <svg aria-hidden="true" className width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                      <circle cx="12" cy="12" r="9" />
                      <path d="M12 7v5l3 2" />
                    </svg>
                     12:30
                  </span>
                  <span>
                    <svg aria-hidden="true" className width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M12 22c4.4 0 7-3.2 7-7.3 0-3.2-2-6.4-5-9.7-.5 3-2 4.2-3 5.5-.7-2-1.8-3.7-3.4-5C6.4 9 5 11.5 5 15c0 4 2.7 7 7 7Z" />
                    </svg>
                     680 千卡
                  </span>
                </div>
                <h3>
                  香煎三文鱼藜麦碗
                </h3>
                <p>
                  挪威三文鱼、藜麦、牛油果与时蔬
                </p>
                <div className="meal-actions">
                  <button className="replace-button">
                    <svg aria-hidden="true" className width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M20 7v5h-5" />
                      <path d="M4 17v-5h5M18.3 9A7 7 0 0 0 6.4 6.4L4 9M5.7 15A7 7 0 0 0 17.6 17.6L20 15" />
                    </svg>
                    换一个
                  </button>
                  <button className="complete-button">
                    <svg aria-hidden="true" className width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                      <path d="m5 12 4 4L19 6" />
                    </svg>
                    标记完成
                  </button>
                </div>
              </div>
            </article>
            <article className="meal-card">
              <div className="meal-image-wrap">
                <img alt="地中海时蔬能量碗" className="meal-image" src="https://images.unsplash.com/photo-1580683750935-cecfc7ea57f0?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=85&w=800&h=600" />
                <span className="meal-tag">
                  晚餐
                </span>
              </div>
              <div className="meal-info">
                <div className="meal-meta">
                  <span>
                    <svg aria-hidden="true" className width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                      <circle cx="12" cy="12" r="9" />
                      <path d="M12 7v5l3 2" />
                    </svg>
                     18:30
                  </span>
                  <span>
                    <svg aria-hidden="true" className width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M12 22c4.4 0 7-3.2 7-7.3 0-3.2-2-6.4-5-9.7-.5 3-2 4.2-3 5.5-.7-2-1.8-3.7-3.4-5C6.4 9 5 11.5 5 15c0 4 2.7 7 7 7Z" />
                    </svg>
                     530 千卡
                  </span>
                </div>
                <h3>
                  地中海时蔬能量碗
                </h3>
                <p>
                  鹰嘴豆、烤南瓜、羽衣甘蓝与芝麻酱
                </p>
                <div className="meal-actions">
                  <button className="replace-button">
                    <svg aria-hidden="true" className width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M20 7v5h-5" />
                      <path d="M4 17v-5h5M18.3 9A7 7 0 0 0 6.4 6.4L4 9M5.7 15A7 7 0 0 0 17.6 17.6L20 15" />
                    </svg>
                    换一个
                  </button>
                  <button className="complete-button">
                    <svg aria-hidden="true" className width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                      <path d="m5 12 4 4L19 6" />
                    </svg>
                    标记完成
                  </button>
                </div>
              </div>
            </article>
          </div>
        </section>
        <aside className="right-panel">
          <section className="nutrition-card">
            <div className="card-heading">
              <div>
                <h2>
                  今日营养
                </h2>
                <p>
                  目标 1,850 千卡
                </p>
              </div>
              <button aria-label="查看营养详情">
                <svg aria-hidden="true" className width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                  <path d="m9 18 6-6-6-6" />
                </svg>
              </button>
            </div>
            <div className="calorie-summary">
              <div className="calorie-ring" style={ background: 'conic-gradient(rgb(82, 113, 92) 22.7027%, rgb(231, 235, 229) 0deg)' }>
                <div>
                  <strong>
                    420
                  </strong>
                  <span>
                    已摄入 / 千卡
                  </span>
                </div>
              </div>
            </div>
            <div className="nutrient-list">
              <div className="nutrient-row">
                <div className="nutrient-label">
                  <span>
                    <i style={ background: 'rgb(217, 133, 104)' }>
                    </i>
                    蛋白质
                  </span>
                  <strong>
                    23 
                    <small>
                      / 95g
                    </small>
                  </strong>
                </div>
                <div className="nutrient-track">
                  <span style={ width: '24.2105%', background: 'rgb(217, 133, 104)' }>
                  </span>
                </div>
              </div>
              <div className="nutrient-row">
                <div className="nutrient-label">
                  <span>
                    <i style={ background: 'rgb(213, 170, 82)' }>
                    </i>
                    碳水
                  </span>
                  <strong>
                    55 
                    <small>
                      / 230g
                    </small>
                  </strong>
                </div>
                <div className="nutrient-track">
                  <span style={ width: '23.913%', background: 'rgb(213, 170, 82)' }>
                  </span>
                </div>
              </div>
              <div className="nutrient-row">
                <div className="nutrient-label">
                  <span>
                    <i style={ background: 'rgb(120, 146, 167)' }>
                    </i>
                    脂肪
                  </span>
                  <strong>
                    13 
                    <small>
                      / 62g
                    </small>
                  </strong>
                </div>
                <div className="nutrient-track">
                  <span style={ width: '20.9677%', background: 'rgb(120, 146, 167)' }>
                  </span>
                </div>
              </div>
            </div>
          </section>
          <section className="water-card">
            <div className="water-title">
              <span>
                <svg aria-hidden="true" className width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M12 2S5 10 5 15a7 7 0 0 0 14 0c0-5-7-13-7-13Z" />
                </svg>
              </span>
              <div>
                <h2>
                  今日饮水
                </h2>
                <p>
                  保持充足水分
                </p>
              </div>
            </div>
            <div className="water-count">
              <strong>
                1500
              </strong>
              <span>
                 / 2,000 ml
              </span>
            </div>
            <div className="water-glasses" aria-label="已喝 6 杯水">
              <button className="glass filled" aria-label="记录到第 1 杯">
                <span>
                </span>
              </button>
              <button className="glass filled" aria-label="记录到第 2 杯">
                <span>
                </span>
              </button>
              <button className="glass filled" aria-label="记录到第 3 杯">
                <span>
                </span>
              </button>
              <button className="glass filled" aria-label="记录到第 4 杯">
                <span>
                </span>
              </button>
              <button className="glass filled" aria-label="记录到第 5 杯">
                <span>
                </span>
              </button>
              <button className="glass filled" aria-label="记录到第 6 杯">
                <span>
                </span>
              </button>
              <button className="glass" aria-label="记录到第 7 杯">
                <span>
                </span>
              </button>
              <button className="glass" aria-label="记录到第 8 杯">
                <span>
                </span>
              </button>
            </div>
            <button className="water-button">
              <svg aria-hidden="true" className width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                <path d="M12 5v14M5 12h14" />
              </svg>
              记录一杯水
            </button>
          </section>
          <section className="tip-card">
            <div className="tip-label">
              <svg aria-hidden="true" className width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                <path d="M20 4c-8.4.2-14 4.1-14 10.1 0 3.2 2.2 5.4 5.2 5.4C17.8 19.5 20 11.3 20 4Z" />
                <path d="M4 21c1.4-5.2 5.2-9 11.4-11.4" />
              </svg>
              今日小贴士
            </div>
            <p>
              慢慢吃饭，让身体有时间感知饱腹。每一口多咀嚼几次，会让消化更轻松。
            </p>
          </section>
        </aside>
      </div>
    </main>
  </div>
</div>