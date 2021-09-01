%% manually load .mat files generated by beta_plots.m, then run the following lines

%lifetime dec-rele
bar(categorical([1:1:5]),[life1_avg,life2_avg,life3_avg,life4_avg,life5_avg]);
hold on
er=errorbar(categorical([1:1:5]),[life1_avg,life2_avg,life3_avg,life4_avg,life5_avg],[life1_se,life2_se,life3_se,life4_se,life5_se],'Color','w');
er.LineStyle = 'none';
xlabel('lifetime ratings');
ylabel('average beta value');
set(gca,'Color','k');
set(gca,'XColor','w');
set(gca,'YColor','w');
hold off
f=gcf;
exportgraphics(f,'testphase_lifetime-beta.png','Resolution',300);

%recent dec-rele
bar(categorical([1:1:5]),[recent1_avg,recent2_avg,recent3_avg,recent4_avg,recent5_avg]);
hold on
errorbar(categorical([1:1:5]),[recent1_avg,recent2_avg,recent3_avg,recent4_avg,recent5_avg],[recent1_se,recent2_se,recent3_se,recent4_se,recent5_se])

hold off

%rep-sup (recent dec-irr)
errorbar([1:4],[pres1_avg,pres7_avg,pres8_avg,pres9_avg],[pres1_se,pres7_se,pres8_se,pres9_se])
legend('repetition effect')
ylabel('average beta value')
labels={'pres1','pres7','pres8','pres9'};
set(gca, 'xtick',1:4)
set(gca, 'xticklabel', labels)

%lifetime dec-irr
errorbar([1:5],[life_irr_1_avg,life_irr_2_avg,life_irr_3_avg,life_irr_4_avg,life_irr_5_avg],[life_irr_1_se,life_irr_2_se,life_irr_3_se,life_irr_4_se,life_irr_5_se])
ylabel('average beta value')
legend('dec-irr lifetime')
set(gca, 'xtick',1:5)
labels={'lifetime_1','lifetime_2','lifetime_3','lifetime_4','lifetime_5'};
set(gca, 'xticklabel', labels)