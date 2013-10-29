% T=find(ERP.times<=70,1,'last'):find(ERP.times>=100,1,'first');
% for i=1:1000
%     for s=1:length(ApeS)
% %         trln=min(TRLS(s,:));
%         trln=100;
%         ind=1:size(ApeS{s},3); I=randperm(length(ind)); ind=ind(I); ind=ind(1:trln);  
%         X=mean(ApeS{s}(C,T,ind),3);
%         X=squeeze(mean(mean(X,2)));
%         AVEsub(s,1,i)=X;
%         ind=1:size(ApeNS{s},3); I=randperm(length(ind)); ind=ind(I); ind=ind(1:trln); 
%         X=mean(ApeNS{s}(C,T,ind),3);
%         X=squeeze(mean(mean(X,2)));
%         AVEsub(s,2,i)=X;
%         ind=1:size(ApeVS{s},3); I=randperm(length(ind)); ind=ind(I); ind=ind(1:trln); 
%         X=mean(ApeVS{s}(C,T,ind),3);
%         X=squeeze(mean(mean(X,2)));
%         AVEsub(s,3,i)=X;
%         ind=1:size(ApeVNS{s},3); I=randperm(length(ind)); ind=ind(I); ind=ind(1:trln); 
%         X=mean(ApeVNS{s}(C,T,ind),3);
%         X=squeeze(mean(mean(X,2)));
%         AVEsub(s,4,i)=X;
%     end % ApeS
% end % i=1:100

clear ApeS ApeNS ApeVS ApeVNS
for i=1:1
    for s=1:length(ApeSITC)
%         trln=min(TRLS(s,:));
        trln=125;
        ind=1:size(ApeSITC{s},4); I=randperm(length(ind)); ind=ind(I); ind=ind(1:trln);  
        X=angle(mean(ApeSITC{s}(:,:,:,ind),4)).*180./pi; % convert to PLV
        X=mean(mean(X,3));
        ApeS(s,:,i)=X;
        
        ind=1:size(ApeNSITC{s},4); I=randperm(length(ind)); ind=ind(I); ind=ind(1:trln);  
        X=angle(mean(ApeNSITC{s}(:,:,:,ind),4)).*180./pi; % convert to PLV
        X=mean(mean(X,3));
        ApeNS(s,:,i)=X;
        
        ind=1:size(ApeVSITC{s},4); I=randperm(length(ind)); ind=ind(I); ind=ind(1:trln);  
        X=angle(mean(ApeVSITC{s}(:,:,:,ind),4)).*180./pi; % convert to PLV
        X=mean(mean(X,3));
        ApeVS(s,:,i)=X;
        
        ind=1:size(ApeVNSITC{s},4); I=randperm(length(ind)); ind=ind(I); ind=ind(1:trln);  
        X=angle(mean(ApeVNSITC{s}(:,:,:,ind),4)).*180./pi; % convert to PLV
        X=mean(mean(X,3));
        ApeVNS(s,:,i)=X;
    end % ApeS
end % i=1:100
